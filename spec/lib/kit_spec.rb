# encoding: UTF-8

require "spec_helper"

describe Tetra::Kit do
  include Tetra::Mockers

  before(:each) do
    create_mock_project

    @project.dry_run
    @project.finish(false)

    @kit = Tetra::Kit.new(@project)
  end

  after(:each) do
    delete_mock_project
  end

  describe "#binary_packages" do
    it "finds binary packages" do
      @project.from_directory(File.join("kit", "m2")) do
        binary_package_path = File.join(".", "com", "company",
                                        "project", "artifact", "1.0")
        FileUtils.mkdir_p(binary_package_path)

        expected_pom = File.join(binary_package_path, "artifact-1.0.pom")
        expected_other_files = [
          File.join(binary_package_path, "artifact-1.0.jar"),
          File.join(binary_package_path, "artifact-1.0.sha1")
        ]

        ([expected_pom] + expected_other_files).each do |file|
          FileUtils.touch(file)
        end

        expected_binary_package = Tetra::BinaryPackage.new(expected_pom, expected_other_files)

        expect(@kit.binary_packages.first).to eql(expected_binary_package)
      end
    end
  end

  describe "#to_spec" do
    it "generates the first version" do
      expect(@kit.to_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Name:           test-project-kit\n")
        expect(spec_lines).to include("Version:        1\n")
        expect(spec_lines).to include("Source0:        %{name}.tar.xz\n")
      end
    end
    it "generates a second version" do
      expect(@kit.to_spec).to be_truthy
      @project.dry_run
      Dir.chdir(@project_path) do
        test_file = File.join("kit", "test")
        File.open(test_file, "w") { |io| io.puts "changed kit content test file" }

        File.open(File.join("output", "test-project-kit", "test-project-kit.spec"), "a") do |io|
          io.write("nonconflicting line")
        end
      end
      @project.finish(false)

      expect(@kit.to_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Name:           test-project-kit\n")
        expect(spec_lines).to include("Version:        2\n")
        expect(spec_lines).to include("Source0:        %{name}.tar.xz\n")
        expect(spec_lines).to include("nonconflicting line\n")
      end
    end
    it "generates a conflicting version" do
      expect(@kit.to_spec).to be_truthy
      @project.dry_run
      Dir.chdir(@project_path) do
        test_file = File.join("kit", "test")
        File.open(test_file, "w") { |io| io.puts "changed kit content test file" }

        spec_path = File.join("output", "test-project-kit", "test-project-kit.spec")
        spec_contents = File.read spec_path

        spec_contents.gsub!(/^Version:.*$/, "CONFLICTING!")

        File.open(spec_path, "w+") do |io|
          io.write(spec_contents)
        end
      end
      @project.finish(false)

      expect(@kit.to_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Name:           test-project-kit\n")
        expect(spec_lines).to include("Source0:        %{name}.tar.xz\n")
        expect(spec_lines).to include("<<<<<<< newly generated\n")
        expect(spec_lines).to include("Version:        2\n")
        expect(spec_lines).to include("=======\n")
        expect(spec_lines).to include("CONFLICTING!\n")
        expect(spec_lines).to include(">>>>>>> user edited\n")
      end
    end
    it "generates a version with binary packages" do
      @project.from_directory(File.join("kit", "m2")) do
        FileUtils.mkdir_p("org1/group1/artifact1/1/")
        FileUtils.touch("org1/group1/artifact1/1/artifact1-1.pom")
        FileUtils.mkdir_p("org2/group2/artifact2/2/")
        FileUtils.touch("org2/group2/artifact2/2/artifact2-2.pom")
      end

      expect(@kit.to_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", "test-project-kit", "test-project-kit.spec"))
        expect(spec_lines).to include("Provides:       mvn(org1.group1:artifact1) == 1\n")
        expect(spec_lines).to include("Provides:       mvn(org2.group2:artifact2) == 2\n")
      end
    end
  end

  describe "#to_archive" do
    it "generates an archive" do
      @project.from_directory("kit") do
        FileUtils.touch("kit_test")
      end

      @kit.to_archive

      @project.from_directory do
        expect(`tar -Jtf output/test-project-kit/test-project-kit.tar.xz`.split).to include("kit_test")
      end
    end
  end
end
