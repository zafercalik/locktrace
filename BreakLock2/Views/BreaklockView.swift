import SwiftUI

// Tahmin geçmişini tutmak için yapı
struct GuessHistory: Identifiable {
    let id = UUID()
    let combination: [Int]
    let feedback: (correctPlace: Int, wrongPlace: Int)
    let dotPositions: [Int: CGPoint] // Bu tahmini çizmek için gerekli nokta pozisyonları
}

struct BreaklockView: View {
    @StateObject private var gameLogic: BreaklockGameLogic
    
    @State private var selectedDotIndices: [Int] = []
    @State private var fixedPathSegments: [CGPoint] = []
    @State private var currentDragPoint: CGPoint? = nil
    @State private var dotPositions: [Int: CGPoint] = [:] // Ana oyun alanı için nokta pozisyonları
    @State private var gameResult: String?
    @State private var showResultAlert: Bool = false
    @State private var gameWon: Bool = false
    
    @State private var guessHistory: [GuessHistory] = []
    
    let numberOfDotsInCombination = 4
    let totalNumberOfDots = 9
    
    let defaultDotSizeRef: CGFloat = 30
    let gameAreaWidthPercentage: CGFloat = 0.70

    @State private var currentDotSize: CGFloat = 30
    @State private var currentSpacing: CGFloat = 60

    let pathOffsetY: CGFloat = -60
    
    @State private var flashScale: CGFloat = 1.0

    @State private var shouldStopDrawingPath: Bool = false

    // YENİ: Deneme sayısını tutmak için değişken
    @State private var guessCount: Int = 0

    init() {
        _gameLogic = StateObject(wrappedValue: BreaklockGameLogic(numberOfDotsInCombination: 4, totalNumberOfDots: 9))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            Path { path in
                guard !shouldStopDrawingPath else { return }

                if fixedPathSegments.count > 0 {
                    path.move(to: fixedPathSegments[0])
                    for i in 1..<fixedPathSegments.count {
                        path.addLine(to: fixedPathSegments[i])
                    }
                }

                if let lastFixedPoint = fixedPathSegments.last, let dragPoint = currentDragPoint, selectedDotIndices.count < numberOfDotsInCombination {
                    if fixedPathSegments.count > 0 && lastFixedPoint != dragPoint {
                        path.move(to: lastFixedPoint)
                        path.addLine(to: dragPoint)
                    }
                }
            }
            .stroke(Color.white, lineWidth: 5)
            .zIndex(0)
            .offset(y: pathOffsetY)

            VStack {
                Text(NSLocalizedString("appname", comment: ""))
                    .font(.system(.title2, design: .monospaced)) // Monospaced tasarımı korur
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                    .padding(.top, 24)

                GeometryReader { gridContainerGeometry in
                    let availableWidth = gridContainerGeometry.size.width
                    let targetGridWidth = availableWidth * gameAreaWidthPercentage
                    
                    let newCalculatedDotSize = defaultDotSizeRef
                    let newCalculatedSpacing = (targetGridWidth - (3 * newCalculatedDotSize)) / 2
                    
                    let finalCalculatedSpacing = max(0, newCalculatedSpacing)
                    
                    Color.clear
                        .onAppear {
                            self.currentDotSize = newCalculatedDotSize
                            self.currentSpacing = finalCalculatedSpacing
                        }
                        .onChange(of: gridContainerGeometry.size.width) { oldValue, newValue in
                            let newTargetGridWidth = newValue * gameAreaWidthPercentage
                            let newDotSize = defaultDotSizeRef
                            let newSpacing = (newTargetGridWidth - (3 * newDotSize)) / 2
                            self.currentDotSize = newDotSize
                            self.currentSpacing = max(0, newSpacing)
                        }

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(currentDotSize), spacing: currentSpacing), count: 3), spacing: currentSpacing) {
                        ForEach(0..<totalNumberOfDots, id: \.self) { index in
                            Circle()
                                .fill(dotColor(for: index))
                                .frame(width: currentDotSize, height: currentDotSize)
                                .overlay(
                                    Circle()
                                        .stroke(borderColor(for: index), lineWidth: 3)
                                )
                                .scaleEffect(index == selectedDotIndices.last ? flashScale : 1.0)
                                .animation(.easeOut(duration: 0.1), value: flashScale)
                                .animation(.default, value: selectedDotIndices)
                                .background(
                                    GeometryReader { dotGeometry in
                                        Color.clear
                                            .onAppear {
                                                dotPositions[index] = dotGeometry.frame(in: .global).midPoint
                                            }
                                            .onChange(of: dotGeometry.frame(in: .global).midPoint)
                                        { oldValue, newValue in
                                            dotPositions[index] = newValue
                                        }
                                    }
                                )
                        }
                    }
                    .frame(width: targetGridWidth, alignment: .center)
                    .position(x: gridContainerGeometry.size.width / 2, y: gridContainerGeometry.size.height / 4)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // YENİ: Deneme Sayısı Metni
                HStack{
                    Text(NSLocalizedString("total_attempt", comment: "") + "\(guessCount)")
                        .font(.system(.title2, design: .monospaced)) // Monospaced tasarımı korur
                        .fontWeight(.bold) // Kalınlık verir
                        .foregroundColor(.white)
                        .padding(.top, 10) // Izgara ile deneme sayısı arasına boşluk
                    
                    Spacer()
                }
                .padding(.bottom, 16)
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(guessHistory) { guess in
                            VStack(spacing: 5) {
                                GuessPathView(
                                    combination: guess.combination,
                                    dotPositions: guess.dotPositions,
                                    dotSize: defaultDotSizeRef * 0.3,
                                    spacing: currentSpacing * 0.3,
                                    totalNumberOfDots: totalNumberOfDots,
                                    originalDefaultDotSizeRef: defaultDotSizeRef
                                )
                                .frame(width: (3 * defaultDotSizeRef * 0.3) + (2 * currentSpacing * 0.3),
                                       height: (3 * defaultDotSizeRef * 0.3) + (2 * currentSpacing * 0.3))
                                
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 1, height: 10)
                                    
                                    ForEach(0..<guess.feedback.correctPlace, id: \.self) { _ in
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 10, height: 10)
                                    }
                                    ForEach(0..<guess.feedback.wrongPlace, id: \.self) { _ in
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                            .frame(width: 10, height: 10)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, -3)
                                .padding(.bottom, 5)
                                .padding(.top, 4)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                //.frame(height: ((3 * defaultDotSizeRef * 0.3) + (2 * currentSpacing * 0.3)) + 10 + 5 + 8)
                .frame(height: 120)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .scrollPosition(id: $scrollID, anchor: .leading)
                .onChange(of: guessHistory.count) { oldValue, _ in
                    if let lastGuessId = guessHistory.first?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                scrollID = lastGuessId
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
                
                Spacer()

            }
            .gesture(dragGesture)
            .zIndex(1)

        }
        .alert(isPresented: $showResultAlert) {
            Alert(
                title: Text(gameWon ? NSLocalizedString("congratulations", comment: "") : NSLocalizedString("game_over", comment: "")),
                message: Text(gameResult ?? ""),
                dismissButton: .default(Text(NSLocalizedString("play_again", comment: ""))) {
                    startGame()
                }
            )
        }
        .navigationBarHidden(true)
    }

    @State private var scrollID: UUID? = nil

    func dotColor(for index: Int) -> Color {
        if selectedDotIndices.contains(index) {
            return Color.white
        } else {
            return Color.gray.opacity(0.8)
        }
    }
    
    func borderColor(for index: Int) -> Color {
        if selectedDotIndices.firstIndex(of: index) != nil {
            return Color.clear
        } else {
            return Color.gray
        }
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if shouldStopDrawingPath || showResultAlert { return }

                if selectedDotIndices.isEmpty {
                    if let touchedDotIndex = findTouchedDot(at: value.startLocation) {
                        if let firstDotPos = dotPositions[touchedDotIndex] {
                            selectedDotIndices.append(touchedDotIndex)
                            fixedPathSegments.append(firstDotPos)
                            currentDragPoint = value.location
                            triggerFlashAnimation()
                        }
                    }
                } else {
                    currentDragPoint = value.location
                    
                    if let touchedDotIndex = findTouchedDot(at: value.location) {
                        guard selectedDotIndices.count < numberOfDotsInCombination else { return }

                        if !selectedDotIndices.contains(touchedDotIndex) {
                            if let newDotPos = dotPositions[touchedDotIndex] {
                                fixedPathSegments.append(newDotPos)
                                selectedDotIndices.append(touchedDotIndex)
                                currentDragPoint = newDotPos
                                triggerFlashAnimation()

                                if selectedDotIndices.count == numberOfDotsInCombination {
                                    shouldStopDrawingPath = true
                                    currentDragPoint = nil

                                    let guessIsCorrect = gameLogic.evaluateGuess(selectedDotIndices)
                                    let feedback = gameLogic.getFeedback(for: selectedDotIndices)
                                    
                                    guessHistory.insert(GuessHistory(combination: selectedDotIndices, feedback: feedback, dotPositions: dotPositions), at: 0)

                                    if gameLogic.isGameOver(currentGuessIsCorrect: guessIsCorrect) {
                                        gameWon = guessIsCorrect
                                        gameResult = gameWon ? NSLocalizedString("congratulations", comment: "") : NSLocalizedString("game_over_detail", comment: "")
                                        showResultAlert = true
                                    } else {
                                        // YENİ: Oyun bitmediyse deneme sayısını artır
                                        guessCount += 1
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            if !showResultAlert {
                                                resetGuess()
                                            }
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            }
            .onEnded { value in
                shouldStopDrawingPath = false
                
                if selectedDotIndices.count == numberOfDotsInCombination || showResultAlert {
                    resetGuess()
                    return
                }

                resetGuess()
            }
    }
    
    func triggerFlashAnimation() {
        withAnimation(.easeOut(duration: 0.1)) {
            flashScale = 1.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.1)) {
                flashScale = 1.0
            }
        }
    }

    func findTouchedDot(at location: CGPoint) -> Int? {
        let touchTolerance = currentDotSize / 2 + 5
        for (index, position) in dotPositions {
            let distance = CGPointDistance(from: location, to: position)
            if distance < touchTolerance {
                return index
            }
        }
        return nil
    }

    private func resetGuess() {
        selectedDotIndices.removeAll()
        fixedPathSegments.removeAll()
        currentDragPoint = nil
        flashScale = 1.0
    }
    
    private func startGame() {
        gameLogic.resetGame()
        resetGuess()
        gameResult = nil
        showResultAlert = false
        gameWon = false
        guessHistory.removeAll()
        guessCount = 1 // YENİ: Oyun başladığında deneme sayısını sıfırla
    }
}

// Global Fonksiyonlar ve Extension'lar
extension CGRect {
    var midPoint: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}

func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
    return sqrt(CGPointDistanceSquared(from: from, to: to))
}

struct BreaklockView_Previews: PreviewProvider {
    static var previews: some View {
        BreaklockView()
    }
}
