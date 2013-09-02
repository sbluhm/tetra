# encoding: UTF-8

require 'spec_helper'

describe Gjp::TemplateManager do
  let(:template_manager) { Gjp::TemplateManager.new }

  describe "#template_path" do
    it "returns the pathname where all templates are stored" do
      relative_path = template_manager.template_path

      File.expand_path(relative_path).should eq File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "template"))
    end
  end

  describe "#copy" do
    it "copies a file from template to another dir" do
      destination = Tempfile.new("TemplateManager spec")
      destination_path = destination.path
      destination.unlink

      template_manager.copy(File.join("src", "CONTENTS"), destination_path)

      File.exist?(destination_path)
    end
  end

  describe "#generate" do
    it "compiles a file from a template and a value objects file" do
      template_path = File.join(template_manager.template_path, "test.erb")
      File.open(template_path, "w") { |io| io.puts "Hello <%= world_property %>" }

      destination = Tempfile.new("TemplateManager spec")
      destination_path = destination.path
      destination.unlink

      class WorldClass        
        def world_property
          "World!"
        end

        def get_binding
         binding
        end
      end

      template_manager.generate("test.erb", WorldClass.new.get_binding, destination_path)
      File.unlink(template_path)

      File.read(destination_path).should eq "Hello World!\n"
    end
  end
end