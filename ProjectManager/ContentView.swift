

import SwiftUI
import CoreData
import Foundation

struct Project: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    let createdBy: String
    var isEditable: Bool
    var category: String
    var date: Date
    var progress: Double
}

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    var context: NSManagedObjectContext?
    
    func addProject(title: String, description: String, createdBy: String, isEditable: Bool, category: String, date: Date, progress: Double) {
        guard let context = context else { return }
        let newProject = Project(title: title, description: description, createdBy: createdBy, isEditable: isEditable, category: category, date: date, progress: progress)
        projects.append(newProject)
        
        let PEntity = NSEntityDescription.insertNewObject(forEntityName: "PEntity", into: context) as! ProjectManager.PEntity
        PEntity.title = title
        PEntity.projectDescription = description
        PEntity.createdBy = createdBy
        PEntity.isEditable = isEditable
        PEntity.category = category
        PEntity.date = date
        PEntity.progress = progress
        saveContext()
    }
    
    
    
    func deleteProject(_ project: Project) {
        guard let context = context else { return }
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.remove(at: index)
        }
        
        let fetchRequest: NSFetchRequest<PEntity> = PEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@ AND createdBy == %@", project.title, project.createdBy)
        
        do {
            let result = try context.fetch(fetchRequest)
            if let PEntity = result.first {
                context.delete(PEntity)
                saveContext()
            }
        } catch {
            print("Failed to delete project: \(error)")
        }
    }
    // In your ProjectsViewModel:
    
    func editProject(_ project: Project, updatedTitle: String, updatedDescription: String, updatedCategory: String, updatedDate: Date, updatedProgress : Double) {
        guard let context = context else { return }
        
        // Find the project to be edited in the projects array
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            // Update the project in the projects array
            projects[index].title = updatedTitle
            projects[index].description = updatedDescription
            projects[index].category = updatedCategory
            projects[index].date = updatedDate
            projects[index].progress = updatedProgress
            
            // Update the corresponding PEntity object in Core Data
            let fetchRequest: NSFetchRequest<PEntity> = PEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title == %@ AND createdBy == %@", project.title, project.createdBy)
            
            do {
                let result = try context.fetch(fetchRequest)
                if let pEntity = result.first {
                    pEntity.title = updatedTitle
                    pEntity.projectDescription = updatedDescription
                    pEntity.category = updatedCategory
                    pEntity.date = updatedDate
                    pEntity.progress = updatedProgress
                    saveContext()
                }
            } catch {
                print("Failed to edit project: \(error)")
            }
        }
    }
    
    
    func fetchProjects() {
        guard let context = context else { return }
        let fetchRequest: NSFetchRequest<PEntity> = PEntity.fetchRequest()
        
        do {
            let result = try context.fetch(fetchRequest)
            projects = result.map { Project(title: $0.title ?? "", description: $0.projectDescription ?? "", createdBy: $0.createdBy ?? "", isEditable: $0.isEditable, category: $0.category ?? "", date: $0.date ?? Date(), progress: $0.progress) }
        } catch {
            print("Failed to fetch projects: \(error)")
        }
    }
    
    private func saveContext() {
        guard let context = context else { return }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: ProjectManager.UEntity.entity(), sortDescriptors: []) var users: FetchedResults<ProjectManager.UEntity>
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var isShowingAddProjectSheet = false
    @State private var selectedProject: Project?
    @State private var username = ""
    @State private var password = ""
    @State private var repassword = ""
    @State private var isLoggedIn = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoggedIn {
                    TabView {
                        MyProjectsView(viewModel: viewModel, username : username)
                            .tabItem {
                                Label(NSLocalizedString("my_projects", comment: ""), systemImage: "folder")
                            }
                        
                        AllProjectsView(viewModel: viewModel, username : username)
                            .tabItem {
                                Label(NSLocalizedString("all_projects", comment: ""), systemImage: "list.bullet")
                            }
                    }
                    .onAppear {
                        viewModel.context = viewContext
                        viewModel.fetchProjects()
                    }
                    .toolbar {
                        //                        ToolbarItem(placement: .navigationBarLeading) {
                        //                            Button(action: {
                        //                                showAlert = true
                        //                            }) {
                        //                                Image(systemName: "square.and.arrow.up")
                        //                            }
                        //                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showAlert = true
                            }) {
                                HStack{
                                    Text(LocalizedStringKey("logout"))
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                    }.alert(isPresented: $showAlert) {
                        Alert(
                            title: Text(LocalizedStringKey("c_logout")),
                            message: Text(LocalizedStringKey("c_logout_text")),
                            primaryButton: .cancel(),
                            secondaryButton: .destructive(Text(LocalizedStringKey("logout")), action: {
                                isLoggedIn = false
                            })
                        )
                    }
                } else {
                    VStack(spacing: 20) {
                        Text(LocalizedStringKey("welcome_message"))
                            .font(.largeTitle)
                        NavigationLink(destination: LoginView(username: $username, password: $password, isLoggedIn: $isLoggedIn)) {
                            Text(LocalizedStringKey("login"))
                                .font(.title)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: RegistrationView(username: $username, password: $password, repassword: $repassword, isLoggedIn: $isLoggedIn)) {
                            Text(LocalizedStringKey("register"))
                                .font(.title)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(Color.blue)
                                .foregroundColor(.white)
                            .cornerRadius(10)                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}


struct MyProjectsView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    var username : String
    @State private var isShowingAddProjectSheet = false
    @State private var newProjectTitle = ""
    @State private var newProjectDescription = ""
    @State private var newProjectCreatedBy = ""
    @State private var newProjectIsEditable = false
    
    var body: some View {
        NavigationView {
            List(viewModel.projects.filter { $0.createdBy==username }) { project in
                NavigationLink(destination: ProjectDetailView(createdUser: username, project: project, viewModel: viewModel)) {
                    Text(project.title)
                }
            }
            .navigationTitle(NSLocalizedString("my_projects", comment: ""))
            .navigationBarItems(
                leading: Button(action: {
                    isShowingAddProjectSheet = true
                }, label: {
                    Image(systemName: "plus")
                }),
                trailing: Button(action: {
                    viewModel.fetchProjects()
                    
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
            )
            .sheet(isPresented: $isShowingAddProjectSheet, content: {
                AddProjectSheet(
                    createdUser : username,
                    isPresented: $isShowingAddProjectSheet,
                    addProject: { title, description, username, isEditable, category, date, progress in
                        viewModel.addProject(
                            title: title,
                            description: description,
                            createdBy: username,
                            isEditable: isEditable,
                            category: category,
                            date: date,
                            progress: progress
                            
                        )
                    }
                    
                )
            })
        }
    }
}

struct AllProjectsView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    var username : String
    var body: some View {
        NavigationView {
            List(viewModel.projects) { project in
                NavigationLink(destination: ProjectDetailView(createdUser : username, project: project, viewModel: viewModel)) {
                    Text(project.title)
                }
            }
            .navigationTitle(NSLocalizedString("all_projects", comment: ""))
            .navigationBarItems(trailing: Button(action: {
                viewModel.fetchProjects()
            }, label: {
                Image(systemName: "arrow.clockwise")
            }))
        }
    }
}

import SwiftUI

struct AddProjectSheet: View {
    var createdUser: String
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var description = ""
    @State private var createdBy = ""
    @State private var isEditable = true
    @State private var category = ""
    @State private var date = Date()
    @State private var progress = 0.0
    
    let options = [
        NSLocalizedString("category_education", comment: ""),
        NSLocalizedString("category_environment", comment: ""),
        NSLocalizedString("category_health_wellness", comment: ""),
        NSLocalizedString("category_social_services", comment: ""),
        NSLocalizedString("category_animal_welfare", comment: ""),
        NSLocalizedString("category_arts_culture", comment: ""),
        NSLocalizedString("category_community_development", comment: ""),
        NSLocalizedString("category_elderly_care", comment: ""),
        NSLocalizedString("category_youth_programs", comment: ""),
        NSLocalizedString("category_human_rights", comment: "")
    ]
    
    
    var addProject: (String, String, String, Bool, String, Date, Double) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("project_details", comment: ""))) {
                    HStack{
                        Text(LocalizedStringKey("title"))
                        TextField("", text: $title)
                    }
                    
                    Text(LocalizedStringKey("description"))
                    TextEditor(text: $description)
                    
                        .frame(minHeight: 200)
                    Picker(NSLocalizedString("catergory", comment: ""), selection: $category) {
                        ForEach(Array(options.enumerated()), id: \.1) { index, option in
                            Text(option)
                                .tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    DatePicker(NSLocalizedString("date", comment: ""), selection: $date, displayedComponents: .date)
                    
                        .padding()
                    Slider(value: $progress, in: 0...100, step: 1)
                        .padding()
                    Text("Progress: \(Int(progress))%")
                    
                }
            }
            .navigationBarTitle(NSLocalizedString("add_project", comment: ""))
            .navigationBarItems(
                leading: Button(action: {
                    isPresented = false
                }, label: {
                    Text(LocalizedStringKey("cancel"))
                }),
                trailing: Button(action: {
                    addProject(title, description, createdUser, isEditable, category, date, progress)
                    isPresented = false
                }, label: {
                    Text(LocalizedStringKey("save"))
                })
            )
        }
    }
}


struct EditProjectSheet: View {
    var createdUser: String
    @State private var updatedTitle: String
    @State private var updatedDescription: String
    @State private var updatedCategory: String
    @State private var updatedDate: Date
    @State private var updatedProgress: Double
    let project: Project
    @ObservedObject var viewModel: ProjectsViewModel
    @Binding var isPresented: Bool
    
    init(createdUser: String, project: Project, viewModel: ProjectsViewModel, isPresented: Binding<Bool>) {
        self.createdUser = createdUser
        self._updatedTitle = State(initialValue: project.title)
        self._updatedDescription = State(initialValue: project.description)
        self._updatedCategory = State(initialValue: project.category)
        self._updatedDate = State(initialValue: project.date)
        self._updatedProgress = State(initialValue: project.progress)
        self.project = project
        self.viewModel = viewModel
        self._isPresented = isPresented
    }
    
    let options = [
        NSLocalizedString("category_education", comment: ""),
        NSLocalizedString("category_environment", comment: ""),
        NSLocalizedString("category_health_wellness", comment: ""),
        NSLocalizedString("category_social_services", comment: ""),
        NSLocalizedString("category_animal_welfare", comment: ""),
        NSLocalizedString("category_arts_culture", comment: ""),
        NSLocalizedString("category_community_development", comment: ""),
        NSLocalizedString("category_elderly_care", comment: ""),
        NSLocalizedString("category_youth_programs", comment: ""),
        NSLocalizedString("category_human_rights", comment: "")
    ]
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("project_details", comment: ""))) {
                    HStack{
                        Text(LocalizedStringKey("title"))
                        TextField("", text: $updatedTitle)
                    }
                    Text(LocalizedStringKey("description"))
                    TextEditor(text: $updatedDescription)
                    
                        .frame(minHeight: 200)
                    Picker(NSLocalizedString("catergory", comment: ""), selection: $updatedCategory) {
                        ForEach(Array(options.enumerated()), id: \.1) { index, option in
                            Text(option)
                                .tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    DatePicker(NSLocalizedString("date", comment: ""), selection: $updatedDate, displayedComponents: .date)
                    
                        .padding()
                    Slider(value: $updatedProgress, in: 0...100, step: 1)
                        .padding()
                    Text("Progress: \(Int(updatedProgress))%")
                    
                }
            }
            .navigationBarTitle(NSLocalizedString("edit_projects", comment: ""))
            .navigationBarItems(
                leading: Button(action: {
                    isPresented = false
                }, label: {
                    Text(LocalizedStringKey("cancel"))
                }),
                trailing: Button(action: {
                    viewModel.editProject(project, updatedTitle: updatedTitle, updatedDescription: updatedDescription, updatedCategory: updatedCategory, updatedDate: updatedDate, updatedProgress : updatedProgress)
                    isPresented = false
                }, label: {
                    Text(LocalizedStringKey("update"))
                })
            )
        }
    }
}


struct ProjectDetailView: View {
    var createdUser : String
    let project: Project
    @ObservedObject var viewModel: ProjectsViewModel
    @State private var showingDeleteAlert = false
    @State private var isShowingEditProjectSheet = false
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var body: some View {
        Form{
            Section {
                HStack {
                    Text(LocalizedStringKey("title"))
                        .foregroundColor(.blue)
                    Text(project.title)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                HStack {
                    Text(LocalizedStringKey("description"))
                        .foregroundColor(.blue)
                    Text(project.description)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                HStack {
                    Text(LocalizedStringKey("created"))
                        .foregroundColor(.blue)
                    Text(project.createdBy)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                HStack {
                    Text(LocalizedStringKey("v_catergory"))
                        .foregroundColor(.blue)
                    Text(project.category)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                HStack {
                    Text(LocalizedStringKey("v_date"))
                        .foregroundColor(.blue)
                    Text(dateFormatter.string(from: project.date))
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                HStack {
                    Text(LocalizedStringKey("progress"))
                        .foregroundColor(.blue)
                    Text("\(String(Int(project.progress)))% Completed")
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                HStack {
                    ProgressView(value: project.progress / 100)
                        .padding()
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                
            }
        }
        .navigationBarItems(trailing: navigationBarTrailingItems)
        .sheet(isPresented: $isShowingEditProjectSheet, content: {
            EditProjectSheet(createdUser : createdUser, project: project, viewModel: viewModel, isPresented: $isShowingEditProjectSheet)
        })
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text(LocalizedStringKey("c_delete")),
                message: Text(LocalizedStringKey("c_delete_text")),
                primaryButton: .cancel(),
                secondaryButton: .destructive(Text(NSLocalizedString("delete", comment: "")), action: {
                    viewModel.deleteProject(project)
                })
            )
        }
    }
    
    @ViewBuilder
    private var navigationBarTrailingItems: some View {
        if project.createdBy == createdUser {
            HStack {
                Button(action: {
                    isShowingEditProjectSheet = true
                    // Edit project
                }, label: {
                    Image(systemName: "pencil")
                })
                Button(action: {
                    showingDeleteAlert = true
                }, label: {
                    Image(systemName: "trash")
                })
            }
        }
    }
}




struct RegistrationView: View {
    @Binding var username: String
    @Binding var password: String
    @Binding var repassword: String
    @Binding var isLoggedIn: Bool
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: UEntity.entity(), sortDescriptors: []) var users: FetchedResults<UEntity>
    
    var body: some View {
        
        VStack {
            Text(LocalizedStringKey("register"))
                .font(.largeTitle)
            
            TextField(LocalizedStringKey("username"), text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField(LocalizedStringKey("password"), text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField(LocalizedStringKey("re_password"), text: $repassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                registerUser()
            }, label: {
                Text(LocalizedStringKey("register"))
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            })
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text(LocalizedStringKey("ok")))
            )
        }
    }
    
    private func registerUser() {
        guard !username.isEmpty && !password.isEmpty && password == repassword else {
            alertTitle = NSLocalizedString("invalid_input", comment: "")
            alertMessage = NSLocalizedString("invalid_text", comment: "")
            showAlert = true
            return
        }
        let userExists = users.contains { $0.username == username }
        
        if !userExists {
            let newUser = UEntity(context: viewContext)
            newUser.username = username
            newUser.password = password
            saveContext()
            
            isLoggedIn = true
        } else {
            alertTitle = NSLocalizedString("user_invalid", comment: "")
            alertMessage = NSLocalizedString("user_invalid_text", comment: "")
            showAlert = true
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

struct LoginView: View {
    @Binding var username: String
    @Binding var password: String
    @Binding var isLoggedIn: Bool
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var isPasswordVisible = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: UEntity.entity(), sortDescriptors: []) var users: FetchedResults<UEntity>
    
    var body: some View {
        VStack {
            Text(LocalizedStringKey("login"))
                .font(.largeTitle)
            
            TextField(LocalizedStringKey("username"), text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack{
                if isPasswordVisible {
                    TextField(LocalizedStringKey("password"), text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                } else {
                    SecureField(LocalizedStringKey("password"), text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.gray)
                }
            }
            
            
            
            Button(action: {
                loginUser()
            }, label: {
                Text(LocalizedStringKey("login"))
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            })
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text(LocalizedStringKey("ok")))
            )
        }
    }
    
    private func loginUser() {
        guard !username.isEmpty && !password.isEmpty else {
            alertTitle = NSLocalizedString("invalid_input", comment: "")
            alertMessage = NSLocalizedString("invalid_text", comment: "")
            showAlert = true
            return
            
        }
        
        let userExists = users.contains { $0.username == username && $0.password == password }
        
        if userExists {
            isLoggedIn = true
        } else {
            alertTitle = NSLocalizedString("login_failed", comment: "")
            alertMessage = NSLocalizedString("login_failed_text", comment: "")
            showAlert = true
            // Show an error message that the login credentials are incorrect
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
