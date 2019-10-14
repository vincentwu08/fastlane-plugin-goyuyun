describe Fastlane::Actions::GoyuyunAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The goyuyun plugin is working!")

      Fastlane::Actions::GoyuyunAction.run(nil)
    end
  end
end
