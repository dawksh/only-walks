import SwiftUI

struct WalkDetailView: View {
    let walk: Walk
    var doodleAnim: Namespace.ID
    @EnvironmentObject var core: CoreDataStack
    @Environment(\.presentationMode) var presentation
    @Binding var walks: [Walk]
    @Binding var selectedWalk: Walk?
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea()
            VStack(spacing: 32) {
                ZStack {
                    DoodleView(path: walk.path, showMarkers: true)
                        .frame(width: isAnimating ? 220 : 120, height: isAnimating ? 220 : 120)
                        .matchedGeometryEffect(id: walk.id, in: doodleAnim, isSource: true)
                        .clipped()
                }
                HStack(spacing: 32) {
                    if walk.distance > 0 && walk.duration > 0 {
                        Text(walk.formattedPace ?? "--:-- /km")
                            .font(.custom("IndieFlower", size: 20))
                            .foregroundColor(.primary)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    if let t = walk.formattedDuration {
                        Text(t)
                            .font(.custom("IndieFlower", size: 20))
                            .foregroundColor(.primary)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    if walk.distance > 0 {
                        Text("\(walk.distance / 1000, specifier: "%.2f") km")
                            .font(.custom("IndieFlower", size: 20))
                            .foregroundColor(.primary)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                }
                Text("delete walk")
                    .font(.custom("IndieFlower", size: 20))
                    .foregroundColor(.red)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isAnimating = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            deleteWalk(walk, core.context)
                            walks = loadWalks(core.context).sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
                            selectedWalk = nil
                        }
                    }
            }
            .padding()
        }
        .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.width > 20 {
                    withAnimation(.spring()) {
                        isAnimating = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedWalk = nil
                    }
                }
            })
        .onAppear {
            withAnimation(.spring()) {
                isAnimating = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { EmptyView() } }
    }
} 