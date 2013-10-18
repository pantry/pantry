ignore ".*.swp"

guard :bundler

guard :shell do
  watch(%r{^(doc/.+\.dot)$}) { |m| system("dot -O -Tpng #{m[1]}") }
end

guard :minitest, include: ["lib"] do
  watch(%r{^test/(.*)\/?(.*)_test\.rb$})
  watch(%r{^lib/pantry/(.*/)?([^/]+)\.rb$}) { |m| "test/unit/#{m[1]}#{m[2]}_test.rb" }
  watch("test/unit/test_helper.rb")         { 'test' }
  watch("test/acceptance/test_helper.rb")   { 'test' }
end
