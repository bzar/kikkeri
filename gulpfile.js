var gulp = require('gulp');
var gulpLiveScript = require('gulp-livescript');
var sassCompiler = require('sass')
var gulpSass = require('gulp-sass')(sassCompiler);

function lsServer(){
  return gulp.src('./src/*.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build'));
};

function lsClient(){
  return gulp.src('./websrc/*.ls')
    .pipe(gulpLiveScript({bare: true}))
    .pipe(gulp.dest('build/web'));
};
function web(){
  return gulp.src('./web/*')
    .pipe(gulp.dest('build/web'));
};
function buildSass(){
  return gulp.src('./sass/*')
    .pipe(gulpSass.sync())
    .pipe(gulp.dest('build/web'));
};
function views(){
  return gulp.src('./views/*.jade')
    .pipe(gulp.dest('build/views'));
};

exports.build = gulp.parallel([lsServer, lsClient, views, web, buildSass]);
exports.default = exports.build;
