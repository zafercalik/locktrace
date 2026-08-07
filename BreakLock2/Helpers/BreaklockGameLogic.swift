import Foundation

class BreaklockGameLogic: ObservableObject {
    @Published var secretCombination: [Int] = []
    @Published var attemptsMade: Int = 0
    @Published private(set) var maxAttempts: Int = 15

    let numberOfDotsInCombination: Int
    let totalNumberOfDots: Int
    private let baseMaxAttempts: Int = 15

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
        attemptsMade = 0
        maxAttempts = baseMaxAttempts
        print("Gizli kombinasyon: \(secretCombination)")
    }

    func evaluateGuess(_ guess: [Int]) -> Bool {
        attemptsMade += 1
        return guess == secretCombination
    }

    func resetGame() {
        generateSecretCombination()
    }

    func grantBonusAttempts(_ count: Int = AdMobConfig.bonusAttemptsPerReward) {
        maxAttempts += count
    }

    var remainingAttempts: Int {
        max(0, maxAttempts - attemptsMade)
    }

    func getSecretCombination() -> [Int] {
        return secretCombination
    }

    func getFeedback(for guess: [Int]) -> (correctPlace: Int, wrongPlace: Int) {
        var correctPlace = 0
        var wrongPlace = 0

        for i in 0..<numberOfDotsInCombination {
            if i < guess.count && i < secretCombination.count {
                if guess[i] == secretCombination[i] {
                    correctPlace += 1
                }
            }
        }

        var tempSecret = [Int?](secretCombination.map { $0 })
        var tempGuess = [Int?](guess.map { $0 })

        for i in 0..<numberOfDotsInCombination {
            if i < tempGuess.count && i < tempSecret.count {
                if tempGuess[i] == tempSecret[i] && tempGuess[i] != nil {
                    tempGuess[i] = nil
                    tempSecret[i] = nil
                }
            }
        }

        for i in 0..<numberOfDotsInCombination {
            if let gVal = tempGuess[i] {
                if let sIndex = tempSecret.firstIndex(where: { $0 == gVal }) {
                    wrongPlace += 1
                    tempSecret[sIndex] = nil
                }
            }
        }

        return (correctPlace, wrongPlace)
    }

    func isGameOver(currentGuessIsCorrect: Bool) -> Bool {
        return currentGuessIsCorrect || attemptsMade >= maxAttempts
    }
}
