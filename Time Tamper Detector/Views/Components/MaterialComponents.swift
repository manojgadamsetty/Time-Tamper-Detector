//
//  MaterialComponents.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import SwiftUI

// MARK: - Material Design Components

struct MaterialCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let backgroundColor: Color
    
    init(
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        backgroundColor: Color = Color(.systemBackground),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
    }
}

struct MaterialButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        case success
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.blue
            case .secondary:
                return Color.gray
            case .danger:
                return Color.red
            case .success:
                return Color.green
            }
        }
        
        var foregroundColor: Color {
            return .white
        }
    }
    
    init(
        title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.backgroundColor)
                    .opacity(isDisabled ? 0.6 : 1.0)
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct StatusIndicator: View {
    let status: String
    let color: Color
    let size: CGFloat
    
    init(status: String, color: Color, size: CGFloat = 16) {
        self.status = status
        self.color = color
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.3), radius: 4)
            
            Text(status)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct MaterialProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    init(progress: Double, color: Color = .blue, height: CGFloat = 8) {
        self.progress = progress
        self.color = color
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    init(icon: String, title: String, value: String, valueColor: Color = .primary) {
        self.icon = icon
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AnimatedCheckmark: View {
    @State private var checkmarkProgress: CGFloat = 0
    @State private var circleProgress: CGFloat = 0
    
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 60, color: Color = .green) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: circleProgress)
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            Path { path in
                let checkmarkWidth = size * 0.6
                let checkmarkHeight = size * 0.3
                let startX = size * 0.2
                let startY = size * 0.5
                
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: startX + checkmarkWidth * 0.4, y: startY + checkmarkHeight))
                path.addLine(to: CGPoint(x: startX + checkmarkWidth, y: startY - checkmarkHeight * 0.2))
            }
            .trim(from: 0, to: checkmarkProgress)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                circleProgress = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                checkmarkProgress = 1.0
            }
        }
    }
}

struct AnimatedXMark: View {
    @State private var xProgress: CGFloat = 0
    @State private var circleProgress: CGFloat = 0
    
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 60, color: Color = .red) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: circleProgress)
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            Group {
                Path { path in
                    let inset = size * 0.25
                    path.move(to: CGPoint(x: inset, y: inset))
                    path.addLine(to: CGPoint(x: size - inset, y: size - inset))
                }
                .trim(from: 0, to: xProgress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                Path { path in
                    let inset = size * 0.25
                    path.move(to: CGPoint(x: size - inset, y: inset))
                    path.addLine(to: CGPoint(x: inset, y: size - inset))
                }
                .trim(from: 0, to: xProgress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                circleProgress = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                xProgress = 1.0
            }
        }
    }
}
