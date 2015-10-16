SandboxedModule = require('sandboxed-module')
assert = require("chai").assert
sinon = require('sinon')
chai = require('chai')
chai.should()
expect = chai.expect
modulePath = require('path').join __dirname, '../../../app/js/HttpController'
ObjectId = require("mongojs").ObjectId

describe "HttpController", ->

	beforeEach ->
		@mongo =
			ObjectId: sinon.stub()
			db:
				packageIndex:
					find: sinon.stub()
		@HttpController = SandboxedModule.require modulePath, requires:
			"logger-sharelatex": @logger = { log: sinon.stub(), setHeader: sinon.stub() }
			"./Errors": @Errors = {}
			"./mongojs": @mongo
		@req = {}
		@res = {
			setHeader: sinon.stub()
		}

	describe "something", ->

		it "should send 200 response", (done) ->
			@res.send = (code) =>
				code.should.equal(200)
				@logger.log.calledWith("Something works").should.equal true
				done()
			@HttpController.something @req, @res

	describe "search", ->

		beforeEach ->
			@limit_fn = sinon.stub()
			@limit_fn.callsArgWith(1, null, [])
			@mongo.db.packageIndex.find.returns {
				limit: @limit_fn
			}

		describe "with language and query", ->

			beforeEach ->
				@req.body = {language: 'python', query: 'somepackage'}

			it "should send a response", (done) ->
				@res.status = (code) =>
					send: (data) =>
						code.should.equal 200
						done()
				@HttpController.search @req, @res

		describe "with only language", ->

			beforeEach ->
				@req.body = {language: 'python'}

			it "should send 400 response", (done) ->
				@res.send = (code) =>
					code.should.equal 400
					done()
				@HttpController.search @req, @res

		describe "with only query", ->

			beforeEach ->
				@req.body = {query: 'wat'}

			it "should send 400 response", (done) ->
				@res.send = (code) =>
					code.should.equal 400
					done()
				@HttpController.search @req, @res

		describe "with empty post body", ->

			beforeEach ->
				@req.body = {}

			it "should send 400 response", (done) ->
				@res.send = (code) =>
					code.should.equal 400
					done()
				@HttpController.search @req, @res

		describe "with no post body", ->

			beforeEach ->
				@req.body = null

			it "should send 400 response", (done) ->
				@res.send = (code) =>
					code.should.equal 400
					done()
				@HttpController.search @req, @res
