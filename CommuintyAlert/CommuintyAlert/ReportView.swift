import SwiftUI
import PhotosUI
import CoreLocation
import MapKit

struct ReportView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: AlertCategory = .weather
    @State private var selectedPriority: AlertPriority = .informational
    @State private var location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var radius: Double = 1000
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showLocationPicker = false
    @State private var navigateToHome = false
    
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Alert Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(AlertCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("Priority", selection: $selectedPriority) {
                        Text("Immediate").tag(AlertPriority.immediate)
                        Text("Important").tag(AlertPriority.important)
                        Text("Informational").tag(AlertPriority.informational)
                    }
                }
                
                Section(header: Text("Location")) {
                    Button(action: {
                        showLocationPicker = true
                    }) {
                        HStack {
                            Text("Select Location")
                            Spacer()
                            Text("\(location.latitude), \(location.longitude)")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Stepper("Radius: \(Int(radius))m", value: $radius, in: 100...10000, step: 100)
                }
                
                Section(header: Text("Photo (Optional)")) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add Photo")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Report Alert")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Submit") {
                    Task {
                        await submitAlert()
                    }
                }
                .disabled(title.isEmpty || description.isEmpty || isLoading)
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedLocation: $location)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
    
    private func submitAlert() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = UserDefaults.standard.string(forKey: "userId") else {
                throw NetworkError.unauthorized
            }
            
            let alert = Alert(
                id: UUID().uuidString,
                title: title,
                description: description,
                category: selectedCategory,
                priority: selectedPriority,
                verificationStatus: VerificationStatus.pending,
                location: Alert.Location(latitude: location.latitude, longitude: location.longitude),
                radius: radius,
                timestamp: Date(),
                source: "User Report",
                isActive: true,
                userId: userId
            )
            
            _ = try await NetworkService.shared.createAlert(alert: alert)
            
            await MainActor.run {
                navigateToHome = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

struct LocationPickerView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region)
                .ignoresSafeArea()
                .navigationTitle("Select Location")
                .navigationBarItems(
                    trailing: Button("Done") {
                        selectedLocation = region.center
                        dismiss()
                    }
                )
        }
    }
}

#Preview {
    ReportView()
} 