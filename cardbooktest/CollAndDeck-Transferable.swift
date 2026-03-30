//
//  CollAndDeck-Transferable.swift
//  cardbooktest
//
//  Created by leo on 2026.03.30.
//

import SwiftUI
import UniformTypeIdentifiers

struct DemoCardInfo2: Transferable, Hashable, Codable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: DemoCardInfo2.self, contentType: .cardType)
    }
    
    var id = UUID()
    var title: String
    var details: String = ""
    enum Place: Int, Codable { case coll, deck }
    var place: Place
}

struct CollAndDeckDemo2: View {
    let layout = Array(repeating: GridItem(.flexible()), count: 3)
    let movingAnim: Animation = .interpolatingSpring(duration: 0.3)
    
    @State var collectionItems: [DemoCardInfo2?] = Array(repeating: nil, count: 15)
    @State var deckItems: [DemoCardInfo2] = [
        .init(title: "1", place: .deck), .init(title: "2", place: .deck), .init(title: "3", place: .deck)
    ]
    @State var presentingItem: DemoCardInfo2? = nil
    
    @Namespace var anm
    @Namespace var nav
//    @State private var draggedItem: DemoCardInfo?
//    @State private var draggedIndex: Int?
//    @State private var sourceList: ListIdentifier?
//    @State private var performing = false
    
    var body: some View {
        NavigationStack {
            main.navigationTitle("Main")
                .navigationDestination(item: $presentingItem) { item in
                    VStack {
                        Text("Details")
                        CardView(item).frame(width: 300)
                    }
                    .navigationTitle("details")
                    .navigationTransition(.zoom(sourceID: item.id, in: nav))
                }
        }
    }
    
    @ViewBuilder var main: some View {
        VStack {
            Text("Collection")
            LazyVGrid(columns: layout) {
                ForEach(Array(collectionItems.enumerated()), id: \.offset) { index, item in
                    if let card = item {
                        CardView(card)
                            .matchedGeometryEffect(id: card.id, in: anm)
                            .matchedTransitionSource(id: card.id, in: nav, configuration: { config in
                                config
                            })
                            .draggable(card) {
                                Text(card.id.uuidString.suffix(4))
                            }
                    } else { // empty
                        RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.2)).overlay {
                            Text("none")
                        }
                        .aspectRatio(1.5, contentMode: .fit)
                        .dropDestination(for: DemoCardInfo2.self) { items, location in
                            if let card = items.first {
                                if card.place == .coll {
                                    if let from = collectionItems.firstIndex(of: card) {
                                        let tmp = collectionItems[from]
                                        withAnimation(movingAnim) {
                                            collectionItems[from] = nil
                                            collectionItems[index] = tmp
                                        }
                                    }
                                } else {
                                    if let from = deckItems.firstIndex(of: card) {
                                        var tmp = deckItems[from]
                                        tmp.place = .coll
                                        withAnimation(movingAnim) {
                                            _ = deckItems.remove(at: from)
                                            collectionItems[index] = tmp
                                        }
                                    }
                                }
                            } else { return false }
                            return true
                        } isTargeted: { targeted in
                            //entered view area
                        }
                    }
                }
            }
            Divider()
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    ForEach(Array(deckItems.enumerated()), id: \.offset) { index, item in
                        CardView(item).frame(width: 100)
                            .matchedGeometryEffect(id: item.id, in: anm)
                            .matchedTransitionSource(id: item.id, in: nav)
                            .draggable(item) {
                                Text(item.id.uuidString.suffix(4))
                            }
                            .visualEffect { content, proxy in
                                content.scaleEffect(scaleValue(proxy)).offset(x: offsetValue(proxy))
                            }
                    }
                }
            }
            .scrollIndicators(.automatic)
            .frame(maxWidth: .infinity).frame(height: 150)
            .background { Color.gray.opacity(0.2) }
            .dropDestination(for: DemoCardInfo2.self) { items, location in
                if let card = items.first {
                    if card.place == .coll {
                        if let from = collectionItems.firstIndex(of: card) {
                            if var tmp = collectionItems[from] {
                                tmp.place = .deck
                                withAnimation(movingAnim) {
                                    collectionItems[from] = nil
                                    deckItems.append(tmp)
                                }
                            }
                        }
                    }
                } else { return false }
                return true
            } isTargeted: { targeted in
                //
            }
            .overlay(alignment: .topTrailing) {
                Button("New") {
                    withAnimation(movingAnim) {
                        deckItems.append(.init(title: "New", place: .deck))
                    }
                }
            }
        }
    }
    
    func scaleValue(_ proxy: GeometryProxy) -> CGFloat {
        let baseX = proxy.frame(in: .scrollView).minX - 60
        return baseX < 0 ? (1.0 + baseX / 1000) : 1.0
    }
    
    func offsetValue(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView).minX
        let screenWidth = proxy.bounds(of: .scrollView)?.width ?? 0
        let center = minX + (proxy.size.width / 2)
        let diff = (screenWidth / 2) - center - 100
        // If it's to the left of center, push it right to create the "stack"
        return diff < 0 ? 0 : diff * 0.5
    }
    
    @ViewBuilder func CardView(_ info: DemoCardInfo2) -> some View {
        RoundedRectangle(cornerRadius: 12).fill(.gray).overlay {
            VStack {
                Text(info.title)
                Text(info.id.uuidString.suffix(4))
            }
        }.onTapGesture {
            presentingItem = info
        }.aspectRatio(1.5, contentMode: .fit)
    }
}
