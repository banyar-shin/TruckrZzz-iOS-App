//
//  ContentView.swift
//  TruckrZzz
//
//  Created by Banyar on 2/17/24.
//

import SwiftUI
import Charts
import CoreBluetooth
import TerraRTiOS

public struct TokenPayload: Decodable{
    let token: String
}

public func generateToken(devId: String, xAPIKey: String, userId: String) -> TokenPayload?{
        let url = URL(string: "https://ws.tryterra.co/auth/user?id=\(userId)")
        
        guard let requestUrl = url else {fatalError()}
        var request = URLRequest(url: requestUrl)
        var result: TokenPayload? = nil
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "terra.token.generation")
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue(devId, forHTTPHeaderField: "dev-id")
        request.setValue(xAPIKey, forHTTPHeaderField: "X-API-Key")
        
        let task = URLSession.shared.dataTask(with: request){(data, response, error) in
            if let data = data{
                let decoder = JSONDecoder()
                do{
                    result = try decoder.decode(TokenPayload.self, from: data)
                    group.leave()
                }
                catch{
                    print(error)
                    group.leave()
                }
            }
        }
        group.enter()
        queue.async(group: group) {
            task.resume()
        }
        group.wait()
        return result
}

public func generateSDKToken(devId: String, xAPIKey: String) -> TokenPayload?{
    
        let url = URL(string: "https://api.tryterra.co/v2/auth/generateAuthToken")
        
        guard let requestUrl = url else {fatalError()}
        var request = URLRequest(url: requestUrl)
        var result: TokenPayload? = nil
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "terra.token.generation")
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue(devId, forHTTPHeaderField: "dev-id")
        request.setValue(xAPIKey, forHTTPHeaderField: "x-api-key")
        
        let task = URLSession.shared.dataTask(with: request){(data, response, error) in
            if let data = data{
                let decoder = JSONDecoder()
                do{
                    result = try decoder.decode(TokenPayload.self, from: data)
                    group.leave()
                }
                catch{
                    print(error)
                    group.leave()
                }
            }
        }
        group.enter()
        queue.async(group: group) {
            task.resume()
        }
        group.wait()
        return result
}

public func sendPayload(_ payload: Update, _ deviceID: String){
    let payloadDictionary: [String: Any] = [
        "timestamp": payload.ts!,
        "val": payload.val!,
        "device_id": deviceID
    ]
    
    let url = URL(string: ENDPOINT)
    
    guard let requestUrl = url else {fatalError()}
    var request = URLRequest(url: requestUrl)
    request.httpMethod = "POST"
    request.setValue("*/*", forHTTPHeaderField: "Accept")
    request.setValue("keep-alive", forHTTPHeaderField: "Connection")
    
    do {
        // Encoding the payload dictionary as JSON and setting it as the HTTP body
        request.httpBody = try JSONSerialization.data(withJSONObject: payloadDictionary)
    } catch {
    print(error)
    }
    let task = URLSession.shared.dataTask(with: request){
        (data, response, error) in
    }
    task.resume()
}


struct Globals {
    static var shared = Globals()
    var shownDevices: [Device] = []
    let cornerradius : CGFloat = 10
    let smallpadding: CGFloat = 12
}

extension Color {
    public static var border : Color {
        Color.init(.sRGB, red: 226/255, green: 239/255, blue: 254/255, opacity: 1)
    }
    
    public static var background : Color {
        Color.init(.sRGB, red: 255/255, green: 255/255, blue: 255/255, opacity: 1)
    }
    
    public static var button : Color {
        Color.init(.sRGB, red: 96/255, green: 165/255, blue: 250/255, opacity: 1)
    }
    
    public static var accent: Color{
        Color.init(.sRGB, red: 42/255, green: 100/255, blue: 246/255, opacity: 1)
    }
}

struct ContentView: View {
    @State private var heartRate = 0.0
    @State private var heartRateHistory: [Double] = []
    
    let terraRT = TerraRT(devId: DEVID, referenceId: "user2") { succ in
        print("TerraRT init: \(succ)")
    }
        
    init(){
        print("Hello World")
        let userId = terraRT.getUserid()
        print("UserId detected: \(userId ?? "None")")
        let tokenPayload = generateSDKToken(devId: DEVID, xAPIKey: XAPIKEY)
        print("TerraSDK token: \(tokenPayload!.token)")
        terraRT.initConnection(token: tokenPayload!.token) { succ in
            print("Connection formed: \(succ)")
        }
        
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 24)]
    }
    
    @State private var visible = false
    @State private var showingWidget = false
    @State private var bleSwitch = false
    
    var body: some View {
        NavigationView{
            VStack{
            	connectionStatus().opacity(visible ? 1 : 0)
                Spacer()
                Text("\(Int(heartRate)) BPM")
                    .font(.system(size: 48))
                    .foregroundColor(heartRate >= 60 || heartRate == 0 ? .primary : .red)
                    .padding()
                Spacer()
                realTimeStreaming().padding([.leading, .trailing, .top, .bottom])
                    .overlay(
                        RoundedRectangle(cornerRadius: Globals.shared.cornerradius)
                            .stroke(Color.border, lineWidth: 1)
                            .padding([.leading, .trailing], 5)
                        )
                connectionButtons().padding([.leading, .trailing, .top, .bottom])
                    .padding([.leading, .trailing, .bottom])
                    .border(Color.clear, width: 1)
            }
            .navigationBarTitle("", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("TruckrZzz").fontWeight(.bold)
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                            .padding(.top, 30)
                    }
                }
                .padding(.top, 20)
        }
    }
    
    private func connectionStatus() -> some View{
        HStack{
            Button(action: {
                let device = terraRT.getConnectedDevice()
                if device != nil {
                    print("getConnectedDevice: \(device!.id), \(device!.deviceName)")
                } else {
                print("getConnectedDevice: none found")
                }
            }, label: {
                Text("Connected")
                    .fontWeight(.bold)
                    .font(.system(size: 12))
                    .foregroundColor(.inverse)
                    .padding(3)
                    .padding(.leading,3)
                    .padding(.trailing,3)
                    .background(
                        Capsule()
                            .foregroundColor(.green)
                    )
            })
        }
    }
    
    private func realTimeStreaming() -> some View{
        HStack{
            Toggle(isOn: $bleSwitch, label: {
                Text("Toggle Streaming").fontWeight(.bold)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding([.top, .bottom], Globals.shared.smallpadding)
                    .padding([.trailing])
            }).onChange(of: bleSwitch){bleSwitch in
                let userId = terraRT.getUserid()
                print("UserId detected: \(userId ?? "None")")
                if (bleSwitch){
                    let device = terraRT.getConnectedDevice()
                    print("startRealtime - BLE")
                    terraRT.startRealtime(
                        type: .BLE,
                        dataType: [.HEART_RATE],
                        callback: { update in
                            sendPayload(update, device!.id)
                            print(update)
                            
                            if let heartRateValue = update.val {
                            	heartRate = heartRateValue
                            }
                        }
                    )
                    
                }
                else {
                    terraRT.stopRealtime(type: .BLE)
                }
            }
        }
    }
    
    private func connectionButtons() -> some View {
        HStack{
            Button(action: {
                print("BLE selected!")
                showingWidget.toggle()
            }, label: {
                    Text("Connect Device")
                    .fontWeight(.bold)
                    .font(.system(size: 16))
                    .foregroundColor(.inverse)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .foregroundColor(.button)
                    )
            })
            .sheet(isPresented: $showingWidget){ terraRT.startBluetoothScan(type: .BLE, callback: {success in
                print("Device Connection Callback: \(success)")
                if showingWidget {
                    showingWidget.toggle()
                }
                if success {
                    visible.toggle()
                }
            })}
            Button(action: {
                print("Disconnecting device!")
                terraRT.disconnect(type: .BLE)
                if visible {
                    visible.toggle()
                }
            }, label: {
                Text("Disconnect Device")
                    .fontWeight(.bold)
                    .font(.system(size: 16))
                    .foregroundColor(.inverse)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .foregroundColor(.button)
                    )
            })
        }
    }
}
