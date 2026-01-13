//
//  AwareSnapshotRenderer.swift
//  Aware
//
//  Renders UI snapshots in various formats for LLM consumption.
//

import Foundation

// MARK: - Snapshot Renderer

/// Renders view tree nodes into various text formats
public struct AwareSnapshotRenderer {
    public let visibleViewCount: Int

    public init(visibleViewCount: Int) {
        self.visibleViewCount = visibleViewCount
    }

    // MARK: - Rendering: Text

    public func renderAsText(_ nodes: [AwareViewNode]) -> String {
        var output = "=== UI Snapshot ===\n"
        output += "Timestamp: \(ISO8601DateFormatter().string(from: Date()))\n"
        output += "Views: \(visibleViewCount)\n\n"

        for node in nodes {
            output += renderNodeText(node, indent: 0)
        }

        return output
    }

    private func renderNodeText(_ node: AwareViewNode, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var line = prefix

        // View ID and label
        if let label = node.label {
            line += "[\(node.id)] \(label)"
        } else {
            line += "[\(node.id)]"
        }

        // Frame
        if let frame = node.frame {
            line += " @ (\(Int(frame.origin.x)),\(Int(frame.origin.y))) \(Int(frame.width))x\(Int(frame.height))"
        }

        // Visual properties
        if let visual = node.visual {
            let props = visual.inlineDescription
            if !props.isEmpty {
                line += " \(props)"
            }
        }

        // Animation state
        if let animation = node.animation {
            let animStr = animation.inlineDescription
            if !animStr.isEmpty {
                line += " \(animStr)"
            }
        }

        line += "\n"

        // State
        if let state = node.state, !state.isEmpty {
            let stateStr = state.sorted(by: { $0.key < $1.key }).map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            line += "\(prefix)  [state: \(stateStr)]\n"
        }

        // Action metadata (button behavior)
        if let action = node.action {
            line += "\(prefix)  [action: \(action.inlineDescription)]\n"
        }

        // Behavior metadata (backend/data source)
        if let behavior = node.behavior {
            let behaviorStr = behavior.inlineDescription
            if !behaviorStr.isEmpty {
                line += "\(prefix)  [behavior: \(behaviorStr)]\n"
            }
        }

        // Children
        for child in node.children {
            line += renderNodeText(child, indent: indent + 1)
        }

        return line
    }

    // MARK: - Rendering: JSON

    public func renderAsJSON(_ nodes: [AwareViewNode]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let snapshot = AwareJSONSnapshot(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            viewCount: visibleViewCount,
            views: nodes.map { nodeToJSONView($0) }
        )

        if let data = try? encoder.encode(snapshot),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }

    private func nodeToJSONView(_ node: AwareViewNode) -> AwareJSONView {
        AwareJSONView(
            id: node.id,
            label: node.label,
            frame: node.frame.map { AwareJSONFrame(x: $0.origin.x, y: $0.origin.y, width: $0.width, height: $0.height) },
            visual: node.visual.map { v in
                AwareJSONVisual(
                    text: v.text,
                    backgroundColor: v.backgroundColor,
                    foregroundColor: v.foregroundColor,
                    font: v.font,
                    opacity: v.opacity < 1.0 ? v.opacity : nil,
                    isTextTruncated: v.isTextTruncated,
                    intrinsicWidth: v.intrinsicSize?.width,
                    intrinsicHeight: v.intrinsicSize?.height,
                    lineCount: v.lineCount,
                    maxLines: v.maxLines,
                    isFocused: v.isFocused,
                    isHovered: v.isHovered,
                    scrollX: v.scrollOffset?.x,
                    scrollY: v.scrollOffset?.y,
                    contentWidth: v.contentSize?.width,
                    contentHeight: v.contentSize?.height
                )
            },
            state: node.state,
            children: node.children.isEmpty ? nil : node.children.map { nodeToJSONView($0) },
            animation: node.animation,
            action: node.action,
            behavior: node.behavior
        )
    }

    // MARK: - Rendering: Markdown

    public func renderAsMarkdown(_ nodes: [AwareViewNode]) -> String {
        var output = "## UI Snapshot\n\n"
        output += "_Captured: \(ISO8601DateFormatter().string(from: Date()))_\n\n"
        output += "**Views:** \(visibleViewCount)\n\n"
        output += "```\n"

        for node in nodes {
            output += renderNodeText(node, indent: 0)
        }

        output += "```\n"
        return output
    }

    // MARK: - Rendering: Compact (Token-Efficient)

    /// Ultra-compact format optimized for LLM token efficiency
    public func renderAsCompact(_ nodes: [AwareViewNode]) -> String {
        var lines: [String] = ["UI:\(visibleViewCount)v"]
        for node in nodes {
            lines.append(renderNodeCompact(node, indent: 0))
        }
        return lines.joined(separator: "\n")
    }

    private func renderNodeCompact(_ node: AwareViewNode, indent: Int) -> String {
        let prefix = String(repeating: " ", count: indent)
        var line = prefix

        // ID and label: "id:Label" or just "id"
        if let label = node.label {
            line += "\(node.id):\(label)"
        } else {
            line += node.id
        }

        // Frame: (WxH@X,Y) - integers only
        if let f = node.frame {
            line += "(\(Int(f.width))x\(Int(f.height))@\(Int(f.origin.x)),\(Int(f.origin.y)))"
        }

        // State: [k=v,k=v]
        if let state = node.state, !state.isEmpty {
            let stateStr = state.sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ",")
            line += "[\(stateStr)]"
        }

        // Visual text if present
        if let text = node.visual?.text, !text.isEmpty {
            let truncated = text.count > 20 ? String(text.prefix(20)) + "…" : text
            line += "{\"\(truncated)\"}"
        }

        // Compact indicators for enhanced properties
        var indicators: [String] = []

        // Overflow indicator
        if node.visual?.isTextTruncated == true {
            indicators.append("TRUNC")
        }

        // Focus/hover
        if node.visual?.isFocused == true { indicators.append("*focus*") }
        if node.visual?.isHovered == true { indicators.append("hover") }

        // Scroll position
        if let offset = node.visual?.scrollOffset, offset.x != 0 || offset.y != 0 {
            indicators.append("@\(Int(offset.x)),\(Int(offset.y))")
        }

        // Animation
        if let anim = node.animation, anim.isAnimating {
            indicators.append("~\(anim.animationType ?? "anim")~")
        }

        // Action (compact)
        if let action = node.action {
            let shortAction = action.actionDescription.prefix(15)
            indicators.append("→\(shortAction)")
        }

        // Behavior (data source only for compact)
        if let src = node.behavior?.dataSource {
            indicators.append("←\(src)")
        }

        if !indicators.isEmpty {
            line += "<\(indicators.joined(separator: " "))>"
        }

        // Children on new lines with indent
        if !node.children.isEmpty {
            for child in node.children {
                line += "\n" + renderNodeCompact(child, indent: indent + 1)
            }
        }

        return line
    }
}
