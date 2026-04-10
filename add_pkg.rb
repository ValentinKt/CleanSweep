require 'xcodeproj'

project_path = 'CleanSweep/CleanSweep.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add local package reference
package_path = 'Packages/ScanEngine'
pkg_ref = project.root_object.add_local_swift_package(package_path)

# Add package product to the target
target.add_swift_package_product('ScanEngine', pkg_ref)

project.save
puts "Added ScanEngine package to project"
