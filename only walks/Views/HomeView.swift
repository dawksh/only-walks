import SwiftUI

struct HomeView: View {
    @State var walks: [Walk] = []
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 8)]
    }
    var body: some View {
        VStack(spacing: 0) {
            if walks.isEmpty {
                Spacer()
                Text("no walks yet")
                    .font(.custom("IndieFlower", size: 22))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(walks) { walk in
                            walk.doodle
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable { walks.shuffle() }
            }
        }
        .background(Color(red: 0.929, green: 0.918, blue: 0.914).ignoresSafeArea())
    }
} 