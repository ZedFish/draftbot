while true
do
  echo "updating from git.."
  git pull

  echo "running rubocop.."
  rubocop lib

  echo "updating documentation.."
  yardoc lib

  echo "starting bot.."
  ruby main.rb
done