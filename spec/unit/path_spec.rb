require 'moduler/path'
require 'support/spec_support'

describe Moduler::Path do
  [ Pathname, Moduler::Path::Ruby, Moduler::Path::Unix, Moduler::Path::Windows ].each do |path_class|
    is_windows = (path_class == Moduler::Path::Windows || (Gem.win_platform? && [ Pathname, Moduler::Path::Ruby ].include?(path_class)))
    describe path_class do
      define_method :path do |str|
        path_class.new(str)
      end
      context "#dirname" do
        tests = {
          ''         => '.',

          'a'        => '.',
          'a/'       => '.',
          'a//'      => '.',


          'b/a'      => 'b',
          'b//a'     => 'b',
          'b/a/'     => 'b',
          'b//a/'    => 'b',
          'b/a//'    => 'b',
          'b//a//'   => 'b',

          'b/c//a//'    => 'b/c',
          'b//c//a//'   => 'b//c',
        }
        if is_windows
          tests.merge!({
            '/'        => '\\',
            '//'       => '\\',
            '///'      => '\\',
            '/a'       => '\\',
            '//a'      => '\\',
            '/a/'      => '\\',
            '//a/'     => '\\',
            '/a//'     => '\\',
            '//a//'    => '\\',

            '/b/a'     => '\\b',
            '/b//a'    => '\\b',
            '/b/a/'    => '\\b',
            '/b//a/'   => '\\b',
            '/b/a//'   => '\\b',
            '/b//a//'  => '\\b',

            '//b/a'    => '\\b',
            '//b//a'   => '\\b',
            '//b/a/'   => '\\b',
            '//b//a/'  => '\\b',
            '//b/a//'  => '\\b',
            '//b//a//' => '\\b',

            '/b//c//a//'  => '\\b//c',
            '//b//c//a//' => '\\b//c',

            '\\'        => '\\',
            '\\\\'       => '\\',
            '\\\\\\'      => '\\',

            'a'        => '.',
            '\\a'       => '\\',
            '\\\\a'      => '\\',

            'a\\'       => '.',
            '\\a\\'      => '\\',
            '\\\\a\\'     => '\\',

            'a\\\\'      => '.',
            '\\a\\\\'     => '\\',
            '\\\\a\\\\'    => '\\',

            'b\\a'      => 'b',
            'b\\\\a'     => 'b',
            'b\\a\\'     => 'b',
            'b\\\\a\\'    => 'b',
            'b\\a\\\\'    => 'b',
            'b\\\\a\\\\'   => 'b',

            '\\b\\a'     => '\\b',
            '\\b\\\\a'    => '\\b',
            '\\b\\a\\'    => '\\b',
            '\\b\\\\a\\'   => '\\b',
            '\\b\\a\\\\'   => '\\b',
            '\\b\\\\a\\\\'  => '\\b',

            '\\\\b\\a'    => '\\b',
            '\\\\b\\\\a'   => '\\b',
            '\\\\b\\a\\'   => '\\b',
            '\\\\b\\\\a\\'  => '\\b',
            '\\\\b\\a\\\\'  => '\\b',
            '\\\\b\\\\a\\\\' => '\\b',

            'b\\c\\\\a\\\\'    => 'b\\c',
            'b\\\\c\\\\a\\\\'   => 'b\\\\c',
            '\\b\\\\c\\\\a\\\\'  => '\\b\\\\c',
            '\\\\b\\\\c\\\\a\\\\' => '\\b\\\\c',
          })
        else
          tests.merge!({
            '/'        => '/',
            '//'       => '/',
            '///'      => '/',
            '/a'       => '/',
            '//a'      => '/',
            '/a/'      => '/',
            '//a/'     => '/',
            '/a//'     => '/',
            '//a//'    => '/',

            '/b/a'     => '/b',
            '/b//a'    => '/b',
            '/b/a/'    => '/b',
            '/b//a/'   => '/b',
            '/b/a//'   => '/b',
            '/b//a//'  => '/b',

            '//b/a'    => '/b',
            '//b//a'   => '/b',
            '//b/a/'   => '/b',
            '//b//a/'  => '/b',
            '//b/a//'  => '/b',
            '//b//a//' => '/b',

            '/b//c//a//'  => '/b//c',
            '//b//c//a//' => '/b//c',

            '\\'          => '.',
            '\\\\'        => '.',
            '\\\\\\'      => '.',

            'a'           => '.',
            '\\a'         => '.',
            '\\\\a'       => '.',

            'a\\'         => '.',
            '\\a\\'       => '.',
            '\\\\a\\'     => '.',
            '\\\\b\\\\c\\\\a\\\\' => '.',
          })
        end

        tests.each do |input, expected|
          tags = []
          #tags = (input == '\\' ? [ :focus ] : [])
          it "#{input.inspect}.dirname == #{expected.inspect}", *tags do
            expect(path(input).dirname.to_s).to eq expected
          end
        end
      end

      context "#basename" do
        tests = {
          ''         => '',

          'a'        => 'a',
          '/a'       => 'a',
          '//a'      => 'a',

          'a/'       => 'a',
          '/a/'      => 'a',
          '//a/'     => 'a',

          'a//'      => 'a',
          '/a//'     => 'a',
          '//a//'    => 'a',

          'b/a'      => 'a',
          'b//a'     => 'a',
          'b/a/'     => 'a',
          'b//a/'    => 'a',
          'b/a//'    => 'a',
          'b//a//'   => 'a',

          '/b/a'     => 'a',
          '/b//a'    => 'a',
          '/b/a/'    => 'a',
          '/b//a/'   => 'a',
          '/b/a//'   => 'a',
          '/b//a//'  => 'a',

          '//b/a'    => 'a',
          '//b//a'   => 'a',
          '//b/a/'   => 'a',
          '//b//a/'  => 'a',
          '//b/a//'  => 'a',
          '//b//a//' => 'a',

          'b/c//a//'    => 'a',
          'b//c//a//'   => 'a',
          '/b//c//a//'  => 'a',
          '//b//c//a//' => 'a'
        }

        if is_windows
          tests.merge!({
            '/'        => '\\',
            '//'       => '\\',
            '///'      => '\\',

            '\\'        => '\\',
            '\\\\'       => '\\',
            '\\\\\\'      => '\\',

            'a'        => 'a',
            '\\a'       => 'a',
            '\\\\a'      => 'a',

            'a\\'       => 'a',
            '\\a\\'      => 'a',
            '\\\\a\\'     => 'a',

            'a\\\\'      => 'a',
            '\\a\\\\'     => 'a',
            '\\\\a\\\\'    => 'a',

            'b\\a'      => 'a',
            'b\\\\a'     => 'a',
            'b\\a\\'     => 'a',
            'b\\\\a\\'    => 'a',
            'b\\a\\\\'    => 'a',
            'b\\\\a\\\\'   => 'a',

            '\\b\\a'     => 'a',
            '\\b\\\\a'    => 'a',
            '\\b\\a\\'    => 'a',
            '\\b\\\\a\\'   => 'a',
            '\\b\\a\\\\'   => 'a',
            '\\b\\\\a\\\\'  => 'a',

            '\\\\b\\a'    => 'a',
            '\\\\b\\\\a'   => 'a',
            '\\\\b\\a\\'   => 'a',
            '\\\\b\\\\a\\'  => 'a',
            '\\\\b\\a\\\\'  => 'a',
            '\\\\b\\\\a\\\\' => 'a',

            'b\\c\\\\a\\\\'    => 'a',
            'b\\\\c\\\\a\\\\'   => 'a',
            '\\b\\\\c\\\\a\\\\'  => 'a',
            '\\\\b\\\\c\\\\a\\\\' => 'a',
          })
        else
          tests.merge!({
            '/'        => '/',
            '//'       => '/',
            '///'      => '/',

            '\\'        => '\\',
            '\\\\'       => '\\\\',
            '\\\\\\'      => '\\\\\\',

            'a'        => 'a',
            '\\a'       => '\\a',
            '\\\\a'      => '\\\\a',

            'a\\'       => 'a\\',
            '\\a\\'      => '\\a\\',
            '\\\\a\\'     => '\\\\a\\',
            '\\\\b\\\\c\\\\a\\\\' => '\\\\b\\\\c\\\\a\\\\',
          })
        end

        tests.each do |input, expected|
          #tags = (input == '\\\\' && expected == '\\' ? [ :focus ] : [])
          tags = []
          it "#{input.inspect}.basename == #{expected.inspect}", *tags do
            expect(path(input).basename.to_s).to eq expected
          end
        end
      end

      describe '#cleanpath' do
        if is_windows
          it "\\\\a\\\\b//c//.cleanpath yields \\a\\b\\c" do
            expect(path("\\\\a\\\\b//c//").cleanpath.to_s).to eq '\\a\\b\\c'
          end
          it "//a//b\\\\c\\\\.cleanpath yields \\a\\b\\c" do
            expect(path("//a//b\\\\c\\\\").cleanpath.to_s).to eq '\\a\\b\\c'
          end
        else
          it "\\\\a\\\\b//c//.cleanpath yields /a/b/c" do
            expect(path("\\\\a\\\\b//c//").cleanpath.to_s).to eq '\\\\a\\\\b/c'
          end
          it "//a//b\\\\c\\\\.cleanpath yields /a/b/c" do
            expect(path("//a//b\\\\c\\\\").cleanpath.to_s).to eq '/a/b\\\\c\\\\'
          end
        end
      end

      describe "#join" do
        if is_windows
          tests = ({
            [ '/a/b', 'c/d/' ]         => '\\a/b\\c/d/',
            [ '//a//b', 'c//d//' ]     => '\\/a//b\\c//d//',
            [ '//a//b///', 'c//d//' ]  => '\\/a//b\\c//d//',
            [ '//', '' ]               => '\\',

            [ '//a//b//', '//c//d//' ] => '//c//d//',
            [ 'a//b//', '//' ]         => '//',
            [ 'a//b//', '//c//d//' ]   => '//c//d//',
            [ '', '//' ]               => '//',

            [ 'a/b', 'c/d/' ]          => 'a/b\\c/d/',
            [ 'a//b', 'c//d//' ]       => 'a//b\\c//d//',
            [ 'a//b//', 'c//d//' ]     => 'a//b\\c//d//',
            [ '', 'a' ]                => 'a',
            [ 'a', '' ]                => 'a',
            [ 'a', 'b' ]               => 'a\\b',
          })
        else
          tests = ({
            [ '/a/b', 'c/d/' ]         => '/a/b/c/d/',
            [ '//a//b', 'c//d//' ]     => '//a//b/c//d//',
            [ '//a//b///', 'c//d//' ]  => '//a//b/c//d//',
            [ '//', '' ]               => '/',

            [ '//a//b//', '//c//d//' ] => '//c//d//',
            [ 'a//b//', '//' ]         => '//',
            [ 'a//b//', '//c//d//' ]   => '//c//d//',
            [ '', '//' ]               => '//',

            [ 'a/b', 'c/d/' ]          => 'a/b/c/d/',
            [ 'a//b', 'c//d//' ]       => 'a//b/c//d//',
            [ 'a//b//', 'c//d//' ]     => 'a//b/c//d//',
            [ '', 'a' ]                => 'a',
            [ 'a', '' ]                => 'a',
            [ 'a', 'b' ]               => 'a/b',
          })
        end

        tests.each do |input, expected|
          #tags = (input == '\\\\' && expected == '\\' ? [ :focus ] : [])
          tags = []
          it "#{input[0].inspect}.join(#{input[1..-1].inspect}) == #{expected.inspect}", *tags do
            expect(path(input[0]).join(*input[1..-1]).to_s).to eq expected
          end
        end
      end
    end
  end
end
