while true 
do
  inotifywait -e modify *.coffee
  echo "compiling `date`"
  coffee -c *.coffee
done

