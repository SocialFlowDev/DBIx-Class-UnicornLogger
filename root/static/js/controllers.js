console.log("controllers.js");
var unicornApp = angular.module('unicornApp', []);
unicornApp.controller('UnicornController', ['$scope', '$http', function($scope, $http) {
    'use strict';
    window.page = $scope;
    $scope.hide_stack_trace = true;
    $scope.orderProp = '-entry_id';
    var original_data = [];
    var rolled_up_data = {};
    $http.get("http://localhost:5001").success(function(data) {
        var munged_data = data.map(function(el) {
            el.runtime = Math.round(el.runtime * 1000 * 100) / 100;
            el.canonical_st = el.stack_trace.join("\n");
            var st = el.stack_trace.map(function(el) {
                return { frame: el };
            });
            el.stack_trace = [];
            el.show_stack_trace = function() {
                el.stack_trace = st;
            };
            return el;
        });
        original_data = munged_data;
        $scope.qs = munged_data;
    });
    $scope.showLog = function() {
        console.log("showLog");
    };
    $scope.showRollup = function() {
        rolled_up_data = {};
        original_data.forEach(function(el){
            var obj = rolled_up_data[el.query] || {
                count: 0,
                stack_trace: {},
                params: [],
                runtime: {
                    total_time_in_query: 0,
                    avg_time: 0,
                    max_time: null,
                    min_time: null
                }
            };
            rolled_up_data[el.query] = obj;
            obj['stack_trace'][el.canonical_st] = el.stack_trace;
            console.log(el.runtime);
            obj['runtime']['total_time_in_query'] += el.runtime;
            var base_avg = obj['count'] * obj['runtime']['avg_time'];
            console.log("base_avg:"+base_avg);
            obj['runtime']['avg_time'] = (
                    base_avg + parseFloat( el.runtime )
                ) / ( obj['count'] + 1 );
            console.log(el.runtime);
            console.log(obj['count']);
            console.log(obj['runtime']['avg_time']);
            console.log(parseFloat(el.runtime));
            if( obj['runtime']['min_time'] === null || el.runtime < obj['runtime']['min_time'] ) {
                obj['runtime']['min_time'] = el.runtime;
            }
            if( obj['runtime']['max_time'] === null || el.runtime > obj['runtime']['max_time'] ) {
                obj['runtime']['max_time'] = el.runtime;
            }
            obj['count']++;
            obj['params'].push(el.params);
        });
        window.rolled_up_data = rolled_up_data;
    };
}]);
