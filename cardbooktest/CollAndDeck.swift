//
//  CollAndDeck.swift
//  cardbooktest
//
//  Created by leo on 2026.03.29.
//

import SwiftUI
import UniformTypeIdentifiers

struct DemoCardInfo: Identifiable, Equatable, Codable, Hashable {
    var id = UUID()
    var title: String
    var details: String = ""
    enum Place: Int, Codable { case coll, deck }
    var place: Place
}

struct CollAndDeckDemo: View {
    let layout = Array(repeating: GridItem(.flexible()), count: 3)
    
    @State var collectionItems: [DemoCardInfo?] = Array(repeating: nil, count: 15)
    @State var deckItems: [DemoCardInfo] = [
        .init(title: "1", place: .deck), .init(title: "2", place: .deck), .init(title: "3", place: .deck)
    ]
    @State var presentingItem: DemoCardInfo? = nil
    
    @Namespace var anm
    @Namespace var nav
//    @State private var draggedItem: DemoCardInfo?
//    @State private var draggedIndex: Int?
//    @State private var sourceList: ListIdentifier?
//    @State private var performing = false
    
    var body: some View {
        NavigationStack {
            main.navigationDestination(item: $presentingItem) { item in
                VStack {
                    Text("Details")
                    CardView(item).frame(width: 300)
                }.navigationTransition(.zoom(sourceID: item.id, in: nav))
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
                            .onDrag {
                                let data = try? JSONEncoder().encode(card)
                                return NSItemProvider(
                                    item: data as NSSecureCoding?, typeIdentifier: UTType.cardType.identifier
                                )
                            }
                    } else { // empty
                        RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.2)).overlay {
                            Text("none")
                        }.aspectRatio(1.5, contentMode: .fit)
                            .onDrop(of: [.cardType], isTargeted: nil) { providers in
                                for p in providers {
                                    _ = p.loadDataRepresentation(for: .cardType) { data, err in
                                        if let data = data, let item = try? JSONDecoder().decode(
                                            DemoCardInfo.self, from: data
                                        ) {
                                            Task { await MainActor.run {
                                                //collectionItems[index] = item
                                                if item.place == .coll {
                                                    if let from = collectionItems.firstIndex(of: item) {
                                                        let card = collectionItems[from]
                                                        withAnimation {
                                                            collectionItems[from] = nil
                                                            collectionItems[index] = card
                                                        }
                                                    }
                                                } else {
                                                    if let from = deckItems.firstIndex(of: item) {
                                                        var card = deckItems[from]
                                                        card.place = .coll
                                                        withAnimation {
                                                            _ = deckItems.remove(at: from)
                                                            collectionItems[index] = card
                                                        }
                                                    }
                                                }
                                            }}
                                        }
                                    }
                                }
                                return true
                            }
//                            .onDrop(of: [.text], delegate: CollDeckDropDelegate(
//                                destinationIndex: index,
//                                destinationList: .top,
//                                topItems: $collectionItems,
//                                bottomItems: $deckItems,
//                                draggedItem: $draggedItem,
//                                draggedIndex: $draggedIndex,
//                                sourceList: $sourceList,
//                                performing: $performing
//                            ))
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
                            .onDrag {
                                let data = try? JSONEncoder().encode(item)
                                return NSItemProvider(
                                    item: data as NSSecureCoding?, typeIdentifier: UTType.cardType.identifier
                                )
                            }.visualEffect { content, proxy in
                                content.scaleEffect(scaleValue(proxy)).offset(x: offsetValue(proxy))
                            }
                    }
                }
            }
            .scrollIndicators(.automatic)
            .frame(maxWidth: .infinity).frame(height: 150)
            .background { Color.gray.opacity(0.2) }
            .onDrop(of: [.cardType], isTargeted: nil) { providers in
                for p in providers {
                    _ = p.loadDataRepresentation(for: .cardType) { data, err in
                        if let data = data, let item = try? JSONDecoder().decode(
                            DemoCardInfo.self, from: data
                        ) {
                            Task { await MainActor.run {
                                if item.place == .coll {
                                    if let from = collectionItems.firstIndex(of: item) {
                                        if var card = collectionItems[from] {
                                            card.place = .deck
                                            withAnimation {
                                                collectionItems[from] = nil
                                                deckItems.append(card)
                                            }
                                            return true
                                        }
                                    }
                                }
                                return false
                            }}
                        }
                    }
                }
                return true
            }
            .overlay(alignment: .topTrailing) {
                Button("New") {
                    withAnimation {
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
    
    @ViewBuilder func CardView(_ info: DemoCardInfo) -> some View {
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

//struct CollDeckDropDelegate: DropDelegate {
//    let destinationIndex: Int
//    let destinationList: ListIdentifier
//    
//    @Binding var topItems: [DemoCardInfo?]
//    @Binding var bottomItems: [DemoCardInfo]
//    
//    @Binding var draggedItem: DemoCardInfo?
//    @Binding var draggedIndex: Int?
//    @Binding var sourceList: ListIdentifier?
//    @Binding var performing: Bool
//
//    func dropEntered(info: DropInfo) {
//        guard let sourceIdx = draggedIndex,
//              let sourceLid = sourceList,
//              let item = draggedItem else { return }
//
//        // Scenario A: Reordering within the same list
//        if sourceLid == .bottom && destinationList == .bottom {
//            if sourceIdx != destinationIndex {
//                withAnimation {
//                    move(in: .bottom, from: sourceIdx, to: destinationIndex)
//                    draggedIndex = destinationIndex
//                }
//            }
//        }
//        // Scenario B: Moving between lists
//        else {
//            withAnimation {
//                if sourceLid == .bottom {
//                    removeFromList(.bottom, at: sourceIdx)
//                    topItems[destinationIndex] = item
//                } else {
//                    topItems[sourceIdx] = nil
//                    insertIntoList(.bottom, item: item, at: destinationIndex)
//                }
//                
//                // Critical: Update tracking so the next "Enter" is treated as a reorder
//                sourceList = destinationList
//                draggedIndex = destinationIndex
//            }
//        }
//    }
//
//    func dropUpdated(info: DropInfo) -> DropProposal? {
//        return DropProposal(operation: .move)
//    }
//
//    func performDrop(info: DropInfo) -> Bool {
//        performing = true
//        withAnimation(.smooth) {
//            draggedItem = nil
//            draggedIndex = nil
//            sourceList = nil
//        } completion: {
//            performing = false
//        }
//        return true
//    }
//    
//    // MARK: - Helper Methods for List Manipulation
//    
//    private func move(in list: ListIdentifier, from: Int, to: Int) {
//        let offset = (to > from) ? to + 1 : to
//        if list == .top {
//            topItems.move(fromOffsets: IndexSet(integer: from), toOffset: offset)
//        } else {
//            bottomItems.move(fromOffsets: IndexSet(integer: from), toOffset: offset)
//        }
//    }
//
//    private func removeFromList(_ list: ListIdentifier, at index: Int) {
//        if list == .top { topItems.remove(at: index) }
//        else { bottomItems.remove(at: index) }
//    }
//
//    private func insertIntoList(_ list: ListIdentifier, item: DemoCardInfo, at index: Int) {
//        if list == .top { topItems.insert(item, at: index) }
//        else { bottomItems.insert(item, at: index) }
//    }
//}
