class Repo
  include Mongoid::Document
  field :slug, type: String
  field :coverage, type: Float
  field :sha, type: String
end
