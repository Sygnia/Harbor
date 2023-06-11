//
//  BrewInstallView.swift
//  Harbor
//
//  Created by Venti on 07/06/2023.
//

import SwiftUI

struct BrewInstallView: View {
    @Binding var isPresented: Bool
    
    @Environment(\.brewUitls)
    var brewUtils
    
    @State var isInstallingBrew = false
    // Timer to periodically check if Homebrew is installed
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Group {
                Text("Homebrew Installation")
                    .padding()
                    .bold()
                    .font(.title)
                Text("""
                    In order to install Apple's Game Porting Toolkit
                    you will need a copy of the x86_64 Homebrew package manager.
                    """)
                .multilineTextAlignment(.center)
            }
            Spacer()
            Group {
                if !isInstallingBrew {
                    Group {
                        if brewUtils.installed {
                            Text("x86_64 Homebrew is installed")
                                .foregroundColor(.green)
                        } else {
                            Text("x86_64 Homebrew is not installed")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .onReceive(timer) { _ in
                            brewUtils.testX64Brew()
                            
                            if brewUtils.installed {
                                timer.upstream.connect().cancel()
                            }
                        }
                    Text("Installing x86_64 Homebrew...")
                }
            }
            .padding()
            Spacer()
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                if brewUtils.installed {
                    Button("Done") {
                        isPresented = false
                    }
                } else {
                    Button("Install") {
                        Task.detached(priority: .userInitiated) {
                            isInstallingBrew = true
                            brewUtils.installX64Brew()
                            isInstallingBrew = false
                        }
                    }
                }
            }   
        }
        .padding()
    }
}

struct BrewInstallView_Previews: PreviewProvider {
    static var previews: some View {
        BrewInstallView(isPresented: Binding.constant(true))
    }
}
