module Tablecloth
  describe App do
    
    context '#trigger' do
      let(:json) {
        {
          payload: {
            action: 'opened',
            pull_request: {
              base: {
                repo: {
                  full_name: 'foo/bar'
                }
              },
              head: {
                sha: 'somesha0r0th3er'
              }
            }
          }.to_json
        }
      }

      it 'sets the initial build status' do
        expect_any_instance_of(app).to receive(:trigger_status).with('foo/bar', 'somesha0r0th3er', 'pending', 'Tablecloth is waiting for your coverage report')
        post '/trigger', json, { 'HTTP_X_GITHUB_EVENT' => 'pull_request' }
      end
      
      it 'creates a repo' do
        post '/trigger', json, { 'HTTP_X_GITHUB_EVENT' => 'pull_request' }
        expect(Repo.count).to eq(1)
        expect(Repo.first.slug).to eq('foo/bar')
        expect(Repo.first.sha).to eq('somesha0r0th3er')
      end
      
    end
    
    context '#coverage' do
      
      context 'triggers a build status' do
        
        it 'with a new repo' do
          Repo.create(slug: 'foo/bar', sha: 'somesha0r0th3er')
          json = {
            result: {
              covered_percent: 75.73
            }
          }
          expect_any_instance_of(app).to receive(:trigger_status).with('foo/bar', 'somesha0r0th3er', 'success', 'Coverage is 75.73%')
          post '/coverage/foo/bar', json
        end
        
        it 'with a repo with increased coverage' do
          Repo.create(slug: 'foo/bar', sha: 'somesha0r0th3er', coverage: 65.73)
          json = {
            result: {
              covered_percent: 75.73
            }
          }
          expect_any_instance_of(app).to receive(:trigger_status).with('foo/bar', 'somesha0r0th3er', 'success', 'Coverage increased by 10.0% to 75.73%')
          post '/coverage/foo/bar', json
        end
        
        it 'with a repo with reduced coverage' do
          Repo.create(slug: 'foo/bar', sha: 'somesha0r0th3er', coverage: 85.73)
          json = {
            result: {
              covered_percent: 75.73
            }
          }
          expect_any_instance_of(app).to receive(:trigger_status).with('foo/bar', 'somesha0r0th3er', 'failure', 'Coverage decreased by 10.0% to 75.73%')
          post '/coverage/foo/bar', json
        end
        
      end
      
    end
  end
end
