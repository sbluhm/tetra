# encoding: UTF-8

require "rest_client"
require "json"
require "open-uri"

# implements the get-source-address subcommand
class SourceAddressGetter

  # returns the pom corresponding to a file or directory, if it can be found
  def self.get_source_address(file)
    (get_source_address_from_pom(file) or get_source_address_from_github(file))
  end

  # returns an scm address in a pom file
  def self.get_source_address_from_pom(file)
    pom = Pom.new(file)
    result = pom.connection_address

    if result != nil
      $log.info("address found in pom for: #{file}")
      result
    end
  end
  
  # returns an scm address looking for it on github
  def self.get_source_address_from_github(file)
    pom = Pom.new(file)

    result = (github_search(pom.artifact_id).first or github_search(pom.group_id).first)
    
    if result != nil
      $log.info("address found on Github for: #{file}")
      result
    end
  end
  
  # returns Giuthub repo addresses based on the keyword
  def self.github_search(keyword)
    p "doing #{keyword}"
    if keyword != nil
      response = RestClient.get "https://api.github.com/legacy/repos/search/" + CGI::escape(keyword), :user_agent => "gjp/" + Gjp::VERSION, :language => "java"
      json = JSON.parse(response.to_s)
    
      json["repositories"].map do |repository|
        "git:" + repository["url"]
      end
    end
  end
end