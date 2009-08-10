# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name = %q{dr_nic_magic_models}
  s.version = "0.9.3"
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["nicwilliams"]
  s.date = %q{2009-08-10}
  s.description = %q{Dr Nic's Magic Models - Invisible validations, assocations and Active Record models themselves!}
  s.email = %q{drnicwilliams@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "website/index.txt", "website/version-raw.txt", "website/version.txt"]
  s.files = ["CHANGELOG", "History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "install.rb", "lib/base.rb", "lib/connection_adapters/abstract/schema_statements.rb", "lib/connection_adapters/abstract_adapter.rb", "lib/connection_adapters/mysql_adapter.rb", "lib/connection_adapters/postgresql_adapter.rb", "lib/dr_nic_magic_models.rb", "lib/dr_nic_magic_models/inflector.rb", "lib/dr_nic_magic_models/magic_model.rb", "lib/dr_nic_magic_models/schema.rb", "lib/dr_nic_magic_models/validations.rb", "lib/dr_nic_magic_models/version.rb", "lib/module.rb", "lib/rails.rb", "scripts/txt2html", "scripts/txt2js", "test.db", "test/abstract_unit.rb", "test/connections/native_mysql/connection.rb", "test/connections/native_postgresql/connection.rb", "test/connections/native_sqlite/connection.rb", "test/dummy_test.rb", "test/env_test.rb", "test/fixtures/adjectives.yml", "test/fixtures/adjectives_fun_users.yml", "test/fixtures/db_definitions/mysql.drop.sql", "test/fixtures/db_definitions/mysql.sql", "test/fixtures/db_definitions/postgresql.sql", "test/fixtures/db_definitions/sqlite.sql", "test/fixtures/fun_users.yml", "test/fixtures/group_memberships.yml", "test/fixtures/group_tag.yml", "test/fixtures/groups.yml", "test/foreign_keys_test.rb", "test/fun_user_plus.rb", "test/invisible_model_access_test.rb", "test/invisible_model_assoc_test.rb", "test/invisible_model_classes_test.rb", "test/magic_module_test.rb", "test/test_existing_model.rb", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.js", "website/template.rhtml", "website/version-raw.js", "website/version-raw.txt", "website/version.js", "website/version.txt"]
  s.homepage = %q{http://magicmodels.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{magicmodels}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Dr Nic's Magic Models - Invisible validations, assocations and Active Record models themselves!}
  s.test_files = ["test/test_existing_model.rb"]
 
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 2.3.3"])
    else
      s.add_dependency(%q<hoe>, [">= 2.3.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 2.3.3"])
  end
end