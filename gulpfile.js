var gulp = require('gulp');
var gulpLiveScript = require('gulp-livescript');

gulp.task('default', function() {
  // place code for your default task here
});

gulp.task('build', ['ls-server', 'ls-client', 'views', 'web']);

gulp.task('ls-server', function() {
  return gulp.src('./src/*.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build'));
});

gulp.task('ls-client', function() {
  return gulp.src('./websrc/*.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build/web'));
});
gulp.task('web', function() {
  return gulp.src('./web/*')
    .pipe(gulp.dest('build/web'));
});
gulp.task('views', function() {
  return gulp.src('./views/*.jade')
    .pipe(gulp.dest('build/views'));
});
