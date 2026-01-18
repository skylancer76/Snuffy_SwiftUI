//
//  BookDogWalkerView.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BookDogWalkerView: View {
    @StateObject private var viewModel = BookDogWalkerViewModel()
    @Environment(\.dismiss) var dismiss
    
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Booking Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Booking Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                // Pet Selection
                                HStack {
                                    Text("Select Pet")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Menu {
                                        ForEach(viewModel.petNames, id: \.self) { petName in
                                            Button(action: {
                                                viewModel.selectedPetName = petName
                                            }) {
                                                HStack {
                                                    Text(petName)
                                                    if viewModel.selectedPetName == petName {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        Text(viewModel.selectedPetName.isEmpty ? "Select Pet" : viewModel.selectedPetName)
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                    .disabled(viewModel.petNames.isEmpty)
                                }
                                .padding()
                                .background(Color.white)
                                
                                Divider().padding(.leading, 16)
                                
                                // Date Picker
                                DatePicker("Select Date", selection: $viewModel.selectedDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(Color.white)
                                
                                Divider().padding(.leading, 16)
                                
                                // Start Time
                                DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(Color.white)
                                
                                Divider().padding(.leading, 16)
                                
                                // End Time
                                DatePicker("End Time", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(Color.white)
                            }
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            
                            Text("Pickup and Drop charges are included.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                        }
                        
                        // Walking Instructions Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Walking Instructions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            TextEditor(text: $viewModel.walkingInstructions)
                                .frame(height: 150)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                        }
                        
                        // Add Address Button
                        Button(action: {
                            viewModel.proceedToAddress()
                        }) {
                            Text("Add Address")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(snuffyPink)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .disabled(viewModel.isLoading || viewModel.selectedPetName.isEmpty)
                    }
                    .padding(.vertical, 24)
                }
                
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: snuffyPink))
                }
            }
            .navigationTitle("Book Dog Walker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchPetNames()
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToAddress) {
                AddAddressView(
                    requestType: .dogWalker,
                    bookingData: viewModel.getBookingData(),
                    currentRequestId: viewModel.currentRequestId
                )
            }
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .alert("No Pets Found", isPresented: $viewModel.showNoPetsAlert) {
                Button("Add Pet") {
                    viewModel.navigateToAddPet()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You currently have no pets. Please add a pet to continue.")
            }
        }
    }
}

#Preview {
    BookDogWalkerView()
}
