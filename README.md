# ExtraMile
ExtraMile+ is a quick app that I made this year to challenge myself to get another app on the App Store. My girlfriend is a big runner and wanted to challenge herself
to run 366 miles this year. So I developed this simple app to help her track her progress towards those 366 miles. 

# Technologies Used
* SwiftUI
* Firebase
* Swift Algorithms

# App Store Link
[ExtraMile+](https://apps.apple.com/us/app/extramile/id6504718247)

# I'm Most Proud Of...
This was the first time I attempted creating UI Designs using code. I was toying around with the app name and what I wanted the theme for the app to be and I ended 
up creating this road design using Swift. After coming up with the design I was motivated to finish the app and get it on the App Store!

Here's the code example for that design: 
```swift
ZStack {
    Color.gray
        .edgesIgnoringSafeArea(.all)
    
    RoundedRectangle(cornerRadius: 30, style: .continuous)
        .foregroundStyle(.linearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
        .rotationEffect(.degrees(135))
        .offset(x: -50, y: -350)
        .frame(width: 1000, height: 500)
    
    VStack {
        Text("ExtraMile \(Image(systemName: "figure.run"))")
            .foregroundStyle(.yellow)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .rotationEffect(.degrees(315))
        Spacer()
    }
    .padding(.top, 75)
    .padding(.leading, -200)
    
    VStack {
        HStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .foregroundStyle(.yellow)
                .frame(width: 100, height: 35)
                .rotationEffect(.degrees(135))
            Spacer()
        }
        .padding(.leading, 275)
        .padding(.top, 0)
        
        HStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .foregroundStyle(.yellow)
                .frame(width: 100, height: 35)
                .rotationEffect(.degrees(135))
            Spacer()
        }
        .padding(.leading, 375)
        .padding(.top, -140)
  
  
        HStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .foregroundStyle(.yellow)
                .frame(width: 100, height: 35)
                .rotationEffect(.degrees(135))
            Spacer()
        }
        .padding(.leading, 475)
        .padding(.top, -250)
  
        HStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .foregroundStyle(.yellow)
                .frame(width: 100, height: 35)
                .rotationEffect(.degrees(135))
            Spacer()
        }
        .padding(.leading, 575)
        .padding(.top, -360)
        
        HStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .foregroundStyle(.yellow)
                .frame(width: 100, height: 35)
                .rotationEffect(.degrees(135))
            
        }
        .padding(.leading, 400)
        .padding(.top, -465)
  
        Spacer()
    }
    .padding(.top, 300)
    .padding(.leading, -50)
}
```

# Project's Future
I'm not sure if I will plan on improving this app, it was more for a quick project to further my portfolio and help with my girlfriends goals. I do want to market
it better to produce more downloads. 
