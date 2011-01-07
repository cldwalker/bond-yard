require 'bacon'
require 'bacon/bits'
require 'mocha'
require 'mocha-on-bacon'
require 'bond/yard'
require 'rbconfig'

class Bacon::Context
  def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end
end
include Bond

module YARD; VERSION = '0.5.2'; module Registry; end; end
  
describe 'Bond.load_yard_gems' do
  def load_yard_gems(*args)
    args = ['blah'] if args.empty?
    Bond.load_yard_gems(*args)
  end

  it 'prints error if unable to require yard' do
    Yard.expects(:require).with('yard').raises(LoadError)
    capture_stderr { load_yard_gems }.should =~ /yard.*not installed/
  end

  it 'prints error if old version of yard' do
    YARD.send :remove_const, :VERSION
    YARD::VERSION = '0.5.0'
    Yard.expects(:require).with('yard')
    capture_stderr { load_yard_gems }.should =~ /yard.*not installed/
    YARD.send :remove_const, :VERSION
    YARD::VERSION = '0.5.2'
  end

  it 'prints error if no yardoc found' do
    Yard.expects(:require).with('yard')
    Yard.expects(:find_yardoc).returns(nil)
    capture_stderr { load_yard_gems('bond') }.should =~ /Didn't.*'bond'.* Unable to find/
  end

  describe 'loads yardoc found by' do
    before {
      Yard.expects(:require).at_least(1).with { require 'fileutils'; true }
      Yard.expects(:create_completion_file)
      M.expects(:load_file)
    }

    it 'registry' do
      YARD::Registry.expects(:yardoc_file_for_gem).returns('/dir/.yardoc')
      load_yard_gems
    end

    describe 'find_gem_file and' do
      before {
        YARD::Registry.expects(:yardoc_file_for_gem).returns(nil)
        M.expects(:find_gem_file).returns('/dir/blah.rb')
      }

      it 'prints building message' do
        Yard.expects(:system)
        capture_stdout { load_yard_gems('bond') }.should =~ /Building.*bond's/
      end

      it "caches yardoc by default" do
        Yard.expects(:system).with {|*args| args.include?('-c') }
        capture_stdout { load_yard_gems }
      end

      it "doesn't cache yardoc with :reload option" do
        Yard.expects(:system).with {|*args| !args.include?('-c') }
        capture_stdout { load_yard_gems('blah', :reload=>true) }
      end

      it "prints multiple messages with :verbose option" do
        Yard.expects(:system).with {|*args| !args.include?('-q') }
        capture_stdout { load_yard_gems('blah', :verbose=>true) }.should =~ /yardoc -n/
      end
    end
  end

  describe 'creates completion file' do
    before {
      Yard.expects(:require).at_least(1).with { require 'fileutils'; true }
      Yard.expects(:find_yardoc).returns('/dir/.yardoc')
      M.expects(:load_file)
    }

    # rubinius implements Kernel#require with File.exists? which is different than MRI
    unless Config::CONFIG["RUBY_SO_NAME"].to_s[/rubinius/i]
    it "with :reload option" do
      File.expects(:exists?).returns(true)
      Yard.expects(:create_completion_file)
      load_yard_gems 'blah', :reload=>true
    end

    it "with new completion file" do
      File.expects(:exists?).returns(false)
      Yard.expects(:create_completion_file)
      load_yard_gems
    end
    end

    describe 'which has' do
      before { YARD::Registry.expects(:load!) }

      it 'methods' do
        Yard.expects(:find_methods_with_options).returns({"Bond::M.start"=>[':one', 'two']})
        expected_body = %[complete(:method=>'Bond::M.start') {\n  ["one", "two"]\n}]
        File.expects(:open).yields mock('block') { expects(:write).with(expected_body) }
        load_yard_gems
      end

      it 'no methods' do
        Yard.expects(:find_methods_with_options).returns({})
        File.expects(:open).yields mock('block') { expects(:write).with('') }        
        load_yard_gems
      end

      it 'methods that map from #initialize to .new' do
        Yard.expects(:find_methods_with_options).returns({"Bond::Agent#initialize"=>[':one', 'two']})
        expected_body = %[complete(:method=>'Bond::Agent.new') {\n  ["one", "two"]\n}]
        File.expects(:open).yields mock('block') { expects(:write).with(expected_body) }
        load_yard_gems
      end
    end
  end
end
