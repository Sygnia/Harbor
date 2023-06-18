//
//  NewBottleDropdown.swift
//  Harbor
//
//  Created by Venti on 08/06/2023.
//

import SwiftUI

struct NewBottleDropdown: View {
    @Binding var isPresented: Bool
    var editingMode: Bool = false

    @State var bottle: HarborBottle
    @State var bottlePath = ""
    @State var isWorking = false

    var body: some View {
        VStack {
            Text(editingMode ? "sheet.edit.title" : "sheet.new.title")
                .font(.title)
                .padding()

            Spacer()

            Form {
                Section {
                    TextField("sheet.new.bottleNameLabel", text: $bottle.name)
                        .onChange(of: bottle.name) { oldValue, newValue in
                            // Prevent it from being empty
                            if newValue == "" {
                                bottle.name = oldValue
                            } else {
                                bottle.name = newValue
                            }
                        }
                }

                // Browsable file picker for new bottle folder
                Section {
                    HStack {
                        TextField("sheet.new.bottlePathLabel", text: $bottlePath)
                        Button("btn.browse") {
                            let dialog = NSOpenPanel()
                            dialog.title = "sheet.new.title"
                            dialog.showsResizeIndicator = true
                            dialog.showsHiddenFiles = false
                            dialog.canChooseDirectories = true
                            dialog.canChooseFiles = false
                            dialog.canCreateDirectories = true
                            dialog.allowsMultipleSelection = false
                            dialog.directoryURL = FileManager.default
                                .urls(for: .documentDirectory, in: .userDomainMask).first
                            if dialog.runModal() == NSApplication.ModalResponse.OK {
                                if let result = dialog.url {
                                    bottlePath = result.path
                                }
                            } else {
                                // User clicked on "Cancel"
                                return
                            }
                        }
                    }
                    .onChange(of: bottlePath) { _, value in
                        bottle.path = URL(fileURLWithPath: value)
                    }
                }
                .disabled(editingMode)

                if editingMode {
                    Section {
                        HStack {
                            TextField("sheet.edit.primaryAppLabel", text: $bottle.primaryApplicationPath)
                            Button("btn.browse") {
                                let dialog = NSOpenPanel()
                                dialog.title = "sheet.edit.primaryApp.popup"
                                dialog.showsResizeIndicator = true
                                dialog.showsHiddenFiles = false
                                dialog.canChooseDirectories = false
                                dialog.canChooseFiles = true
                                dialog.canCreateDirectories = false
                                dialog.allowsMultipleSelection = false
                                dialog.directoryURL = bottle.path
                                if dialog.runModal() == NSApplication.ModalResponse.OK {
                                    if let result = dialog.url {
                                        bottle.primaryApplicationPath = bottle.pathFromUnixPath(result)
                                    }
                                } else {
                                    // User clicked on "Cancel"
                                    return
                                }
                            }
                        }
                    }
                    Section {
                        TextField("sheet.edit.primaryAppArgsLabel", text: $bottle.primaryApplicationArgument)
                        HStack {
                            TextField("sheet.edit.primaryAppWorkDirLabel", text: $bottle.primaryApplicationWorkDir)
                            Button("btn.Auto") {
                                // Path up to the executable
                                // Remove the executable name from the Windows path
                                let path = bottle.primaryApplicationPath
                                    .replacingOccurrences(of: "\\", with: "/")
                                    .components(separatedBy: "/")
                                    .dropLast()
                                    .joined(separator: "\\")
                                bottle.primaryApplicationWorkDir = path
                            }
                            Button("btn.browse") {
                                let dialog = NSOpenPanel()
                                dialog.title = "sheet.edit.primaryApp.popup"
                                dialog.showsResizeIndicator = true
                                dialog.showsHiddenFiles = false
                                dialog.canChooseDirectories = true
                                dialog.canChooseFiles = false
                                dialog.canCreateDirectories = true
                                dialog.allowsMultipleSelection = false
                                dialog.directoryURL = bottle.path
                                if dialog.runModal() == NSApplication.ModalResponse.OK {
                                    if let result = dialog.url {
                                        bottle.primaryApplicationWorkDir = bottle.pathFromUnixPath(result)
                                    }
                                } else {
                                    // User clicked on "Cancel"
                                    return
                                }
                            }
                        }
                    }
                }
            }

            if isWorking {
                // Bar indicating progress
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding()
            }

            Spacer()

            // Cancel and Create buttons
            HStack {
                Button("btn.cancel") {
                    isPresented = false
                }
                Button(editingMode ? "btn.done" : "btn.create") {
                    if editingMode {
                        // Save the bottle
                        if let bottleIndex = BottleLoader.shared.bottles.firstIndex(where: { $0.id == bottle.id }) {
                            BottleLoader.shared.bottles[bottleIndex] = bottle
                        }
                        isPresented = false
                    } else {
                        // Create the bottle
                        isWorking = true
                        Task.detached {
                            bottle.initializeBottle()
                            Task { @MainActor in
                                BottleLoader.shared.bottles.append(bottle)
                                isWorking = false
                                isPresented = false
                            }
                        }
                    }
                }
                .disabled(bottle.name == "" || bottle.path.absoluteString == "file:///" || isWorking)
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 500)
    }
}

struct EditBottleView: View {
    @Binding var isPresented: Bool
    var bottle: HarborBottle
    var body: some View {
        // Basically reuse New in editing mode
        NewBottleDropdown(isPresented: $isPresented, editingMode: true,
                          bottle: bottle, bottlePath: bottle.path.absoluteString)
    }

}

struct NewBottleDropdown_Previews: PreviewProvider {
    static var previews: some View {
        EditBottleView(isPresented: Binding.constant(true),
                          bottle: HarborBottle(id: UUID(), name: "My Bottle",
                                               path: URL(fileURLWithPath: "/Users/venti/Documents/My Bottle")))
    }
}
