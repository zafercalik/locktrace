import Foundation

class BreaklockGameLogic: ObservableObject {
    @Published var secretCombination: [Int] = []
    @Published var attemptsMade: Int = 0
    let numberOfDotsInCombination: Int
    let totalNumberOfDots: Int
    
    // Oyunun maksimum deneme hakkı
    let maxAttempts: Int = 30

    init(numberOfDotsInCombination: Int, totalNumberOfDots: Int) {
        self.numberOfDotsInCombination = numberOfDotsInCombination
        self.totalNumberOfDots = totalNumberOfDots
        generateSecretCombination()
    }

    func generateSecretCombination() {
        secretCombination = []
        var availableDots = Array(0..<totalNumberOfDots)
        for _ in 0..<numberOfDotsInCombination {
            if let randomIndex = availableDots.indices.randomElement() {
                secretCombination.append(availableDots.remove(at: randomIndex))
            }
        }
        attemptsMade = 0 // Her yeni oyunda denemeleri sıfırla
        print("Gizli kombinasyon: \(secretCombination)")
    }

    func evaluateGuess(_ guess: [Int]) -> Bool {
        attemptsMade += 1
        return guess == secretCombination
    }
    
    func resetGame() {
        generateSecretCombination()
    }
    
    func getSecretCombination() -> [Int] {
        return secretCombination
    }

    // YENİ FONKSİYON: Geri bildirim noktalarını hesapla
    func getFeedback(for guess: [Int]) -> (correctPlace: Int, wrongPlace: Int) {
        var correctPlace = 0
        var wrongPlace = 0
        
        // Doğru konumda doğru sayılar
        for i in 0..<numberOfDotsInCombination {
            if i < guess.count && i < secretCombination.count { // Dizi sınırlarını kontrol et
                if guess[i] == secretCombination[i] {
                    correctPlace += 1
                }
            }
        }
        
        // Doğru sayı ama yanlış konumda
        // Kopya diziler kullanarak zaten sayılmış olanları tekrar saymamayı garantile
        var secretCopy = secretCombination
        var guessCopy = guess
        
        // Önce correctPlace olanları her iki kopyadan da sil
        var tempSecret = [Int?](secretCopy.map { $0 })
        var tempGuess = [Int?](guessCopy.map { $0 })
        
        for i in 0..<numberOfDotsInCombination {
            if i < tempGuess.count && i < tempSecret.count {
                if tempGuess[i] == tempSecret[i] && tempGuess[i] != nil {
                    tempGuess[i] = nil
                    tempSecret[i] = nil
                }
            }
        }
        
        // Sonra doğru sayı ama yanlış yerdekileri bul
        for i in 0..<numberOfDotsInCombination {
            if let gVal = tempGuess[i] {
                if let sIndex = tempSecret.firstIndex(where: { $0 == gVal }) {
                    wrongPlace += 1
                    tempSecret[sIndex] = nil // Bu sayıyı bir daha sayma
                }
            }
        }
        
        return (correctPlace, wrongPlace)
    }
    
    // Oyunun bitip bitmediğini kontrol eden helper (tahmin doğruysa veya deneme hakkı bittiyse)
    func isGameOver(currentGuessIsCorrect: Bool) -> Bool {
        return currentGuessIsCorrect || attemptsMade >= maxAttempts
    }
}
