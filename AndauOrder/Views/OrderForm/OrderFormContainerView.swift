import SwiftUI
import SwiftData

struct OrderFormContainerView: View {
    let orderRecord: OrderRecord
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OrderFormViewModel?

    var body: some View {
        Group {
            if let viewModel {
                formContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OrderFormViewModel(orderRecord: orderRecord, modelContext: modelContext)
            }
        }
        .onChange(of: orderRecord.id) {
            viewModel = OrderFormViewModel(orderRecord: orderRecord, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private func formContent(viewModel: OrderFormViewModel) -> some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar(viewModel: viewModel)

            Divider()

            // Current tab content
            Group {
                switch viewModel.currentTab {
                case .customerInfo:
                    CustomerInfoView(formData: Bindable(viewModel).formData)
                case .products:
                    ProductSelectionView(formData: Bindable(viewModel).formData)
                case .customization:
                    CustomizationView(formData: Bindable(viewModel).formData)
                case .pricing:
                    PricingView(formData: Bindable(viewModel).formData)
                case .reviewChecklist:
                    ReviewChecklistView(formData: Bindable(viewModel).formData)
                case .reviewSubmit:
                    ReviewSubmitView(viewModel: viewModel)
                }
            }
        }
        .navigationTitle(viewModel.formData.customerDisplayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    SyncStatusBadge(status: viewModel.syncStatus)
                    Button("Save") {
                        viewModel.save()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    @ViewBuilder
    private func tabBar(viewModel: OrderFormViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(OrderFormTab.allCases) { tab in
                    Button {
                        withAnimation {
                            viewModel.currentTab = tab
                        }
                    } label: {
                        Label(tab.title, systemImage: tab.icon)
                            .font(.subheadline)
                            .fontWeight(viewModel.currentTab == tab ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.currentTab == tab
                                    ? Color.accentColor.opacity(0.12)
                                    : Color.clear
                            )
                            .foregroundStyle(
                                viewModel.currentTab == tab
                                    ? Color.accentColor
                                    : .secondary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
