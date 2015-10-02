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
		@HttpController = SandboxedModule.require modulePath, requires:
			"logger-sharelatex": @logger = { log: sinon.stub(), setHeader: sinon.stub() }
			"./Errors": @Errors = {}
		@req = {}
		@res = {}

	describe "something", ->

		it "should send 200 response", (done) ->
			@res.send = (code) =>
				code.should.equal(200)
				@logger.log.calledWith("Something works").should.equal true
				done()
			@HttpController.something @req, @res
