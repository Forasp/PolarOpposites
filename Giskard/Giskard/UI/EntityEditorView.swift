//
//  EntityEditorView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/28/25.
//

import SwiftUI
import Spatial

struct EntityEditorView: View {
    @State var entity: Entity
    @State private var isDirty: Bool = false
    @State private var pitch: Double = 0
    @State private var yaw: Double = 0
    @State private var roll: Double = 0
    @State private var magnitude: Double = 0
    @State private var capabilityList: [String] = ["None"]

    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Section(header: Text("Basic")) {
                    TextField("Entity Name", text: $entity.name)
                        .onChange(of: entity.name) { _, _ in isDirty = true }
                        .frame(alignment: .leading)
                }
                
                Section{
                    Text("Transform")
                    VStack(alignment: .leading) {
                        Text("Position")
                        HStack {
                            TextField("X", value: $entity.position.x, formatter: NumberFormatter())
                                .frame(width: 48)
                            TextField("Y", value: $entity.position.y, formatter: NumberFormatter())
                                .frame(width: 48)
                            TextField("Z", value: $entity.position.z, formatter: NumberFormatter())
                                .frame(width: 48)
                        }
                        
                        Text("Rotation")
                        HStack {
                            TextField("X", value: $entity.rotation.vector.x, formatter: NumberFormatter())
                                .frame(width: 48)
                            TextField("Y", value: $entity.rotation.vector.y, formatter: NumberFormatter())
                                .frame(width: 48)
                            TextField("Z", value: $entity.rotation.vector.z, formatter: NumberFormatter())
                                .frame(width: 48)
                            TextField("W", value: $entity.rotation.vector.z, formatter: NumberFormatter())
                                .frame(width: 48)
                        }
                    }
                    
                    TextField("Capabilities (Comma Separated)", value: $capabilityList, formatter: ListFormatter())
                        .onChange(of: capabilityList) {
                            entity.RemoveAllCapabilities()
                            for item in $0{
                                entity.AddCapability(capability: item)
                            }
                        }
                }
            }
            .frame(alignment: .leading)
            .padding()
            .navigationTitle(entity.name.isEmpty ? "Entity" : entity.name)
            .toolbar {
                if isDirty {
                    Button("Save") {
                        // Save logic here (write JSON file)
                        isDirty = false
                    }
                    .keyboardShortcut("S", modifiers: .command)
                }
            }
        }
    }
}

#Preview {
    EntityEditorView(entity: Entity("Test Entity"))
}
