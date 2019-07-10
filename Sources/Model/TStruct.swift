/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/// Protocol for Generated Structs to conform to
/// Dictionary maps field names to internal IDs and uses Reflection
/// to iterate through all fields.
/// `writeFieldValue(_:name:type:id:)` calls `TSerializable.write(to:)` internally
/// giving a nice recursive behavior for nested TStructs, TLists, TMaps, and TSets
public protocol TStruct: TSerializable {
    static var fieldIds: [String: Int32] { get }
    static var structName: String { get }
}


extension TStruct {

    public static var fieldIds: [String: (id: Int32, type: TType)] {
        return [:]
	}

	private static var customPropertyMapping: [String : String]  {
		return ["customDescription" : "description"]
	}

    public static var thriftType: TType {
        return .struct
    }

    public func write(to proto: TProtocol) throws {
        // Write struct name first
        try proto.writeStructBegin(name: Self.structName)

        try forEach { name, value, id in
            // Write to protocol
            try proto.writeFieldValue(value, name: name,
                                      type: value.thriftType, id: id)
        }
        try proto.writeFieldStop()
        try proto.writeStructEnd()
    }

    /// Provides a block for handling each (available) thrift property using reflection
    /// Caveat: Skips over optional values

    /// Provides a block for handling each (available) thrift property using reflection
    ///
    /// - parameter block: block for handling property
    ///
    /// - throws: rethrows any Error thrown in block
    private func forEach(_ block: (_ name: String, _ value: TSerializable, _ id: Int32) throws -> Void) rethrows {
        // Mirror the object, getting (name: String?, value: Any) for every property
        let mirror = Mirror(reflecting: self)

        // Iterate through all children, ignore empty property names
        for (propertyName, propertyValue) in mirror.children {
			guard var propertyName = propertyName
				else {
					continue
			}

			if let customProperty = Self.customPropertyMapping[propertyName] {
				propertyName = customProperty
			}

            guard let unwrappedValue = unwrap(any: propertyValue) as? TSerializable,
                  let id = Self.fieldIds[propertyName]
            else {
                continue
            }

            try block(propertyName, unwrappedValue, id)
        }
    }

    /// Any can mysteriously be an Optional<Any> at the same time,
    /// this checks and always returns Optional<Any> without double wrapping
    /// we then try to bind value as TSerializable to ignore any extension properties
    /// and the like and verify the property exists and grab the Thrift
    /// property ID at the same time
    ///
    /// - parameter any: Any instance to attempt to unwrap
    ///
    /// - returns: Unwrapped Any as Optional<Any>
    private func unwrap(any: Any) -> Any? {
        let mi = Mirror(reflecting: any)

        guard mi.displayStyle == .optional
        else {
            return any
        }

        guard let (_, some) = mi.children.first
        else {
            return nil
        }

        return some
    }
}
