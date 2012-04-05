require 'spec_helper'

describe EldarScrolls::Config do
  describe '#initialize' do
    subject{ EldarScrolls::Config.new(YAML.load(@schema)) }  
    it 'should add a question key for each key of the schema' do
      @schema = <<-YAML
      - test:
          type: string
      YAML
      subject.questions.should be_key('test')
    end

    it 'should instantiate the correct question type for each question' do
      @schema = <<-YAML
      - string:
          type: string
      - boolean:
          type: boolean
      - multiple_choice:
          type: multiple_choice
      YAML
      subject.questions['string'].should be_kind_of(EldarScrolls::Config::Prompt)
      subject.questions['boolean'].should be_kind_of(EldarScrolls::Config::TrueFalse)
      subject.questions['multiple_choice'].should be_kind_of(EldarScrolls::Config::MultipleChoice)
    end

    it 'should error on invalid question type' do
      @schema = <<-YAML
      - invalid:
          type: invalid
      YAML
      lambda{ subject }.should raise_error(ArgumentError)
    end

    describe '#compile' do
      let(:lines) { subject.compile.split("\n") }
      before do
        @schema = <<-YAML
        - string:
            type: string
            prompt: Give me a string?
            if: is_true
        - boolean:
            type: boolean
            prompt: Yes or no?
            unless: is_false
            if_scroll: awesome
        - multiple_choice:
            type: multiple_choice
            choices: [[ABC, abc], [DEF, def]]
            unless_scroll: awesome
        YAML
      end

      it 'should include all questions' do
        lines.size.should == 4
      end

      it 'should handle "if"' do
        lines[1].should be_include("config['is_true']")
      end

      it 'should handle "unless"' do
        lines[2].should be_include("!config['is_false']")
      end

      it 'should handle "if_scroll"' do
        lines[2].should be_include("scroll?('awesome')")
      end

      it 'should handle "unelss_scroll"' do
        lines[3].should be_include("!scroll?('awesome')")
      end
    end

    describe EldarScrolls::Config::Prompt do
      subject{ EldarScrolls::Config::Prompt }
      it 'should compile to a prompt' do
        subject.new({'prompt' => "What's your favorite color?"}).question.should == 'ask_wizard("What\'s your favorite color?")'
      end
    end

    describe EldarScrolls::Config::TrueFalse do
      subject{ EldarScrolls::Config::TrueFalse }
      it 'should compile to a yes? question' do
        subject.new({'prompt' => 'Yes yes?'}).question.should == 'yes_wizard?("Yes yes?")'
      end
    end

    describe EldarScrolls::Config::MultipleChoice do
      subject{ EldarScrolls::Config::MultipleChoice }
      it 'should compile into a multiple_choice' do
        subject.new({'prompt' => 'What kind of fruit?', 'choices' => [['Apples', 'apples'], ['Bananas', 'bananas']]}).question.should ==
          'multiple_choice("What kind of fruit?", [["Apples", "apples"], ["Bananas", "bananas"]])'
      end
    end
  end
end