module Tablecloth
  module Helpers
    
    def trigger_status(repo_name, sha, status, message)
      @client.create_status(
        repo_name,
        sha,
        status,
        description: message,
        context: 'Tablecloth'
      )
    end
    
  end
end
