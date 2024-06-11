import XCTest
@testable import ProjectManager

class ProjectManagerTests: XCTestCase {
    var viewModel: ProjectsViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ProjectsViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testAddProject() {
        viewModel.addProject(
            title: "Test Project",
            description: "This is a test project",
            createdBy: "John Doe",
            isEditable: true,
            category: "Test Category",
            date: Date(),
            progress: 50.0
        )
        
        XCTAssertEqual(viewModel.projects.count, 1)
        let project = viewModel.projects.first!
        XCTAssertEqual(project.title, "Test Project")
        XCTAssertEqual(project.description, "This is a test project")
        XCTAssertEqual(project.createdBy, "John Doe")
        XCTAssertTrue(project.isEditable)
        XCTAssertEqual(project.category, "Test Category")
        // Add assertions for other properties as needed
    }
    
    func testDeleteProject() {
        let project = Project(
            title: "Test Project",
            description: "This is a test project",
            createdBy: "John Doe",
            isEditable: true,
            category: "Test Category",
            date: Date(),
            progress: 50.0
        )
        
        viewModel.projects = [project]
        
        XCTAssertEqual(viewModel.projects.count, 1)
        
        viewModel.deleteProject(project)
        
        XCTAssertEqual(viewModel.projects.count, 0)
    }
    
    func testEditProject() {
        let project = Project(
            title: "Test Project",
            description: "This is a test project",
            createdBy: "John Doe",
            isEditable: true,
            category: "Test Category",
            date: Date(),
            progress: 50.0
        )
        
        viewModel.projects = [project]
        
        XCTAssertEqual(viewModel.projects.count, 1)
        
        viewModel.editProject(
            project,
            updatedTitle: "Updated Project",
            updatedDescription: "This is an updated project",
            updatedCategory: "Updated Category",
            updatedDate: Date(),
            updatedProgress: 75.0
        )
        
        XCTAssertEqual(viewModel.projects.count, 1)
        let updatedProject = viewModel.projects.first!
        XCTAssertEqual(updatedProject.title, "Updated Project")
        XCTAssertEqual(updatedProject.description, "This is an updated project")
        XCTAssertEqual(updatedProject.category, "Updated Category")
        XCTAssertEqual(updatedProject.progress, 75.0)
        // Add assertions for other properties as needed
    }
    
    // Add more test cases as needed
    
}
