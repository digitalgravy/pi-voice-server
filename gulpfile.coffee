gulp            = require "gulp"
coffee          = require "gulp-coffee"
jasmine         = require "gulp-jasmine"
sourcemaps      = require "gulp-sourcemaps"
uglify          = require "gulp-uglify"
concat          = require "gulp-concat"
gif             = require "gulp-if"

gulp.task "default", ["test", "compile"], ->

gulp.task "compile", ->
  gulp.src([
        "./public/lib/*.js"
        "./public/src/*.coffee"
      ])
      .pipe(sourcemaps.init())
      .pipe(gif(/[.]coffee$/, coffee()))
      .pipe(concat("app.js"))
      .pipe(sourcemaps.write())
      .pipe(gulp.dest("./public/js/"))

gulp.task "test", ->
  gulp.src("./spec/*.spec.*")
      .pipe(jasmine(
              verbose: true
            ))

gulp.task "watch:test", ["test"], ->
  gulp.watch([
              "./lib/**/*.coffee"
              "./spec/**/*.spec.*"
            ], ["test"])