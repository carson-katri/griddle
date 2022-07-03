//
//  SwiftUIView.swift
//  
//
//  Created by Carson Katri on 7/1/22.
//

import TokamakShim
import Foundation

@usableFromInline enum GridRowKey: LayoutValueKey {
    @usableFromInline static let defaultValue: GridRowID? = nil
}

@usableFromInline enum GridCellColumns: LayoutValueKey {
    @usableFromInline static let defaultValue: Int = 1
}

@usableFromInline enum GridCellAnchor: LayoutValueKey {
    @usableFromInline static let defaultValue: UnitPoint? = nil
}

@usableFromInline enum GridColumnAlignment: LayoutValueKey {
    @usableFromInline static let defaultValue: HorizontalAlignment = .center
}

@usableFromInline enum GridCellUnsizedAxes: LayoutValueKey {
    @usableFromInline static let defaultValue: Axis.Set = []
}

public extension View {
    @inlinable func gridCellColumns(_ count: Int) -> some View {
        return layoutValue(key: GridCellColumns.self, value: count)
    }
    
    @inlinable func gridCellAnchor(_ anchor: UnitPoint) -> some View {
        return layoutValue(key: GridCellAnchor.self, value: anchor)
    }
    
    @inlinable func gridColumnAlignment(_ guide: HorizontalAlignment) -> some View {
        return layoutValue(key: GridColumnAlignment.self, value: guide)
    }
    
    @inlinable func gridCellUnsizedAxes(_ axes: Axis.Set) -> some View {
        return layoutValue(key: GridCellUnsizedAxes.self, value: axes)
    }
}

@usableFromInline final class GridRowID: CustomDebugStringConvertible {
    @usableFromInline let alignment: VerticalAlignment?
    
    @usableFromInline init(alignment: VerticalAlignment?) {
        self.alignment = alignment
    }
    
    @usableFromInline var debugDescription: String {
        "\(ObjectIdentifier(self))"
    }
}
struct GridRow<Content: View>: View {
    let id: GridRowID
    let content: Content
    
    init(alignment: VerticalAlignment? = nil, @ViewBuilder content: () -> Content) {
        self.id = .init(alignment: alignment)
        self.content = content()
    }
    
    var body: some View {
        content
            .layoutValue(key: GridRowKey.self, value: id)
    }
}

struct Grid: Layout {
    let alignment: Alignment
    let horizontalSpacing: CGFloat?
    let verticalSpacing: CGFloat?
    
    init(alignment: Alignment = .center, horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    struct Cache {
        struct Row {
            let id: GridRowID?
            var columns: [Column]
            
            struct Column {
                let subview: LayoutSubview
                var span: Int
                let flexibility: (width: Bool, height: Bool)
            }
        }
        
        var rows = [Row]()
        var columnWidths = [Int: CGFloat]()
        var rowHeights = [CGFloat]()
        var horizontalSpacing = [Int: CGFloat]()
        var verticalSpacing = [Int: CGFloat]()
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        return subviews.reduce(into: Cache()) { partialResult, subview in
            let id = subview[GridRowKey.self]
            let size = subview.sizeThatFits(ProposedViewSize.infinity)
            let column = Cache.Row.Column(
                subview: subview,
                span: subview[GridCellColumns.self],
                flexibility: (size.width == .infinity, size.height == .infinity)
            )
            if id != nil && id === partialResult.rows.last?.id {
                partialResult.rows[partialResult.rows.count - 1].columns.append(column)
            } else {
                partialResult.rows.append(Cache.Row(id: id, columns: [column]))
            }
        }
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        cache.columnWidths.removeAll()
        cache.rowHeights.removeAll()
        
        let rows = cache.rows.count
        var columns = cache.rows
            .map { $0.columns.reduce(into: 0) { $0 += $1.span } }
            .max() ?? 0
        
        let proposal = proposal.replacingUnspecifiedDimensions()
        
        for (rowIndex, row) in cache.rows.enumerated() {
            guard row.id == nil else { continue }
            for columnIndex in 0..<row.columns.count {
                cache.rows[rowIndex].columns[columnIndex].span = columns
            }
        }
        
        for (rowIndex, row) in cache.rows.enumerated() {
            var spannedColumns = 0
            for (columnIndex, column) in row.columns.enumerated() {
                if row.columns.indices.contains(columnIndex + 1) {
                    if let overrideSpacing = self.horizontalSpacing {
                        cache.horizontalSpacing[spannedColumns + (column.span) - 1] = overrideSpacing
                    } else {
                        let distance = column.subview.spacing.distance(
                            to: row.columns[columnIndex + 1].subview.spacing,
                            along: .horizontal
                        )
                        if distance > cache.horizontalSpacing[spannedColumns + column.span - 1, default: .zero] {
                            cache.horizontalSpacing[spannedColumns + column.span - 1] = distance
                        }
                    }
                }
                
                if cache.rows.indices.contains(rowIndex + 1),
                   cache.rows[rowIndex + 1].columns.indices.contains(columnIndex) {
                    if let overrideSpacing = self.verticalSpacing {
                        cache.verticalSpacing[rowIndex] = overrideSpacing
                    } else {
                        let distance = column.subview.spacing.distance(
                            to: cache.rows[rowIndex + 1].columns[columnIndex].subview.spacing,
                            along: .vertical
                        )
                        if distance > cache.verticalSpacing[rowIndex, default: .zero] {
                            cache.verticalSpacing[rowIndex] = distance
                        }
                    }
                }
                
                spannedColumns += column.span
            }
            if spannedColumns > columns {
                columns = spannedColumns
            }
        }
        
        let totalHorizontalSpacing = cache.horizontalSpacing.reduce(into: .zero) { $0 += $1.value }
        let totalVerticalSpacing = cache.verticalSpacing.reduce(into: .zero) { $0 += $1.value }
        
        let divviedWidth = (proposal.width - totalHorizontalSpacing) / CGFloat(columns)
        let divviedHeight = (proposal.height - totalVerticalSpacing) / CGFloat(rows)
        
        var flexRows = 0
        var flexHeight = (proposal.height - totalVerticalSpacing)
        for row in cache.rows {
            var maxHeight: CGFloat = .zero
            var rowHeight = divviedHeight
            var spannedColumns = 0
            var hasFlexItems = false
            for column in row.columns {
                guard !column.flexibility.width && !column.flexibility.height else {
                    hasFlexItems = true
                    spannedColumns += column.span
                    continue
                }
                let spacing = ((spannedColumns - 1)..<(spannedColumns + column.span - 2))
                    .reduce(into: .zero) { $0 += cache.horizontalSpacing[$1, default: .zero] }
                let size = column.subview.dimensions(in: .init(
                    width: divviedWidth * CGFloat(column.span) + spacing,
                    height: rowHeight
                ))
                for columnIndex in spannedColumns..<(spannedColumns + column.span) {
                    if (size.width / CGFloat(column.span)) > cache.columnWidths[columnIndex, default: .zero] {
                        cache.columnWidths[columnIndex] = size.width / CGFloat(column.span)
                    }
                }
                if size.height > rowHeight {
                    rowHeight = size.height
                }
                if size.height > maxHeight {
                    maxHeight = size.height
                }
                spannedColumns += column.span
            }
            cache.rowHeights.append(maxHeight)
            flexHeight -= maxHeight
            if hasFlexItems {
                flexRows += 1
            }
        }
        
        flexHeight /= CGFloat(flexRows)
        
        var height = CGFloat.zero
        let flexWidth = divviedWidth
        
        for (rowIndex, row) in cache.rows.enumerated() {
            let rowHeight = flexHeight + cache.rowHeights[rowIndex]
            var spannedColumns = 0
            for column in row.columns {
                guard column.flexibility.width || column.flexibility.height else {
                    spannedColumns += column.span
                    continue
                }
                let unsizedAxes = column.subview[GridCellUnsizedAxes.self]
                let size = column.subview.dimensions(in: .init(
                    width: unsizedAxes.contains(.horizontal)
                        ? (spannedColumns..<(spannedColumns + column.span))
                            .reduce(into: .zero) { $0 += cache.columnWidths[$1, default: .zero] }
                        : flexWidth * CGFloat(column.span),
                    height: unsizedAxes.contains(.vertical)
                        ? cache.rowHeights[rowIndex]
                        : rowHeight
                ))
                let eachColumnWidth = size.width / CGFloat(column.span)
                for columnIndex in spannedColumns..<(spannedColumns + column.span) {
                    if eachColumnWidth > cache.columnWidths[columnIndex, default: .zero] {
                        cache.columnWidths[columnIndex] = eachColumnWidth
                    }
                }
                if size.height > cache.rowHeights[rowIndex] {
                    cache.rowHeights[rowIndex] = size.height
                }
                spannedColumns += column.span
            }
            height += cache.rowHeights[rowIndex]
        }
        
        return .init(
            width: cache.columnWidths.values.reduce(into: CGFloat.zero) { $0 += $1 } + totalHorizontalSpacing,
            height: height + totalVerticalSpacing
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        var y = bounds.minY
        for (rowIndex, row) in cache.rows.enumerated() {
            var x = bounds.minX
            let rowHeight = cache.rowHeights[rowIndex]
            var spannedColumns = 0
            
            for column in row.columns {
                let spacing = (spannedColumns..<(spannedColumns + column.span - 1))
                    .reduce(into: .zero) { $0 += cache.horizontalSpacing[$1, default: .zero] }
                let width = (spannedColumns..<(spannedColumns + column.span))
                    .reduce(into: .zero) { $0 += cache.columnWidths[$1, default: .zero] } + spacing
                let proposal = ProposedViewSize(
                    width: width,
                    height: rowHeight
                )
                let dimensions = column.subview.dimensions(in: proposal)
                let anchor = column.subview[GridCellAnchor.self] ?? UnitPoint(
                    x: dimensions.width == 0 ? 0 : dimensions[alignment.horizontal] / dimensions.width,
                    y: dimensions.height == 0 ? 0 : dimensions[row.id?.alignment ?? alignment.vertical] / dimensions.height
                )
                column.subview.place(
                    at: .init(
                        x: x + (width * anchor.x) - (dimensions.width * anchor.x),
                        y: y + (rowHeight * anchor.y) - (dimensions.height * anchor.y)
                    ),
                    proposal: proposal
                )
                for spannedColumnIndex in (spannedColumns..<(spannedColumns + column.span)) {
                    x += cache.columnWidths[spannedColumnIndex, default: .zero] + cache.horizontalSpacing[spannedColumnIndex, default: .zero]
                }
                spannedColumns += column.span
            }
            y += rowHeight + cache.verticalSpacing[rowIndex, default: .zero]
        }
    }
}
