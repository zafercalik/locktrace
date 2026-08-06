//
//  WelcomeView.swift
//  BreakLock2
//
//  Created by Zafer Calik on 12.07.2025.
//

import SwiftUI

struct WelcomeView: View {
    // Oyun ekranına geçişi kontrol etmek için bir @State değişkeni
    @State private var showGame: Bool = false

    var body: some View {
        // NavigationStack iOS 16+ için daha modern bir yaklaşımdır.
        // Eğer eski iOS versiyonlarını hedefliyorsanız NavigationView kullanabilirsiniz.
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // Arka plan rengi

                VStack(spacing: 20) {
                    Text(NSLocalizedString("appname", comment: ""))
                        .font(.system(.largeTitle, design: .monospaced)) // Monospaced tasarımı korur
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)

                    Text(NSLocalizedString("game_rules", comment: ""))
                        .font(.system(.title2, design: .monospaced)) // Monospaced tasarımı korur
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    ScrollView {
                        Text(NSLocalizedString("game_description", comment: ""))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                    }
                    .frame(maxHeight: 300) // ScrollView'e maksimum yükseklik vererek taşmasını engelle
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    
                    HStack(spacing: 20){
                        Spacer()
                        
                        Image("img1")
                            .frame(width: 120, height: 120)
                            .padding(.vertical, 10)
                        
                        Image("img2")
                            .frame(width: 120, height: 120)
                            .padding(.vertical, 10)
                        
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                    )
                    .padding(.horizontal, 10)

                    Spacer()

                    // Başlat butonu
                    Button {
                        showGame = true
                    } label: {
                        Text("OYNA")
                            .font(.system(.title2, design: .monospaced)) // Monospaced tasarımı korur
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 60)
                            .background(Color.blue)
                            .cornerRadius(30)
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 50)
                }
            }
            // showGame true olduğunda BreaklockView'a otomatik geçiş yapar
            .navigationDestination(isPresented: $showGame) {
                BreaklockView()
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
