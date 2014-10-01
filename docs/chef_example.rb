# The +chef.run.cookbook+ resource is in scope.

attribute :github_url, Types::URL
attribute :credentials, Types::Credentials

resource :organization do
  # In scope: chef.run.resource_type_definition:chef.organization.
  # +resource+:
  # - +url+ is the resource URL relative to the Chef root.
  # - +root+ is the current Chef root.
  # - +parent+ is the containing resource.
  # - +resource_type+ is the resource type.
  # - +dsl+ is the pure resource DSL.
  # - +scope+ is the
  # DSL from +context.parent_resource.context+ is available.
  #
  # +context.parent+ is the parent resource or root.
  # +context.root+ is the
  #

  attribute :name, String
  attribute :address do
    attribute :street, String
    attribute :city, String
    attribute :state, String, :equal_to => %w(WA CO TX NC)
  end
  attribute :members, Array[] do |context|
    # The attribute type (the array) is in scope.
    # - +parent+ represents the parent attribute
    # - +parent+ represents the parent attribute (or the resource).
    # - +path+ represents the parent path.
    # - +
    # The attribute itself is in scope.  "resource" represents the resource
  end

  resource :repository do
    attribute :name, String
    attribute :full_name
  end

  recipe :blah do
  end
end

attribute :members

resource :user do
  attribute :name, String
end

resource :load_balancer_group do
  attribute :lead_balancer, types.reference()
end

#
# Resources have standard recipes/actions.
#
# The +github.patch+ resource (the recipe) is in scope.  "resource" is a
# property of the recipe.
#
recipe :patch do

end

recipe :get do
end
