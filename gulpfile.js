var gulp = require('gulp');
var gulpLiveScript = require('gulp-livescript');
var nodemon = require('gulp-nodemon');

gulp.task('default', ['build']);

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


gulp.task('watch', function() {
  gulp.watch('src/*.ls', ['ls-server']);
  gulp.watch('websrc/*.ls', ['ls-client']);
  gulp.watch('web/*', ['web']);
  gulp.watch('views/*.jade', ['views']);
});

gulp.task('nodemon', function() {
  nodemon({
    script: 'build/app.js',
    ext: 'js',
    env: {'NODE_ENV': 'development'},
    watch: ['build/*']
  });
});
gulp.task('dev', ['build', 'watch', 'nodemon']);

