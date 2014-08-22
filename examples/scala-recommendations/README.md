Distributed Recommendation Engine with RDD-based Model using MLlib's ALS
========================================================================

This document describes a recommendation engine that is based on Apache Spark's
MLlib collaborative filtering algorithm.


Prerequisite
------------

Make sure you have built PredictionIO and setup storage described
[here](/README.md).


High Level Description
----------------------

This engine demonstrates how one can integrate MLlib's algorithms that produce
an RDD-based model, deploy it in production and serve real-time queries.

For details about MLlib's collaborative filtering algorithms, please refer to
https://spark.apache.org/docs/latest/mllib-collaborative-filtering.html.

All code definition can be found [here](src/main/scala/Run.scala).


### Data Source

Training data is located at `/examples/data/movielens.txt`. Values are delimited
by double colons (::). The first column are user IDs. The second column are item
IDs. The third column are ratings. In this example, they are represented as
`RDD[Rating]`, as described in the official MLlib guide.


### Preparator

The preparator in this example is an identity function, i.e. no further
preparation is done on the training data.


### Algorithm

This example engine contains one single algorithm that wraps around MLlib. The
`train()` method simply calls MLlib's `ALS.train()` method.


### Serving

This example engine uses `FirstServing`, which serves only predictions from the
first algorithm. Since there is only one algorithm in this engine, predictions
from MLlib's ALS algorithm will be served.


Training a Model
----------------

This example provides a set of ready-to-use parameters for each component
mentioned in the previous section. They are located inside the `params`
subdirectory.

Before training, you must let PredictionIO know about the engine. Run the
following command to build and register the engine.
```
$ cd $PIO_HOME/examples/scala-recommendations
$ ../../bin/pio register
```
where `$PIO_HOME` is the root directory of the PredictionIO code tree.

To start training, use the following command.
```
$ cd $PIO_HOME/examples/scala-recommendations
$ ../../bin/pio train
```
This will train a model and save it in PredictionIO's metadata storage. Notice
that when the run is completed, it will display a run ID, like below.
```
2014-08-09 18:24:27,070 INFO  SparkContext - Job finished: saveAsObjectFile at Run.scala:67, took 0.362254 s
2014-08-09 18:24:27,099 INFO  APIDebugWorkflow$ - Metrics is null. Stop here
2014-08-09 18:24:27,199 INFO  APIDebugWorkflow$ - Saved engine instance with ID: LG0tzG4mSY267sLGgp6L0A
```


Deploying a Real-time Prediction Server
---------------------------------------

Following from instructions above, you should have trained a model. Use the
following command to start a server.
```
$ cd $PIO_HOME/examples/scala-recommendations
$ ../../bin/pio deploy
```
This will create a server that by default binds to http://localhost:8000. You
can visit that page in your web browser to check its status.

To perform real-time predictions, try the following.
```
$ curl -H "Content-Type: application/json" -d '[1,4]' http://localhost:8000
```
Congratulations! You have just trained an ALS model and is able to perform real
time prediction distributed across an Apache Spark cluster!


Production Prediction Server Deployment
---------------------------------------

Prediction servers support reloading models on the fly with the latest completed
run.

1.  Assuming you already have a running prediction server from the previous
    section, go to http://localhost:8000 to check its status. Take note of the
    **Run ID** at the top.

2.  Run training and deploy again.

    ```
    $ cd $PIO_HOME/examples/scala-recommendations
    $ ../../bin/pio train
    $ ../../bin/pio deploy
    ```

3.  Refresh the page at http://localhost:8000, you should see the prediction
    server status page with a new **Run ID** at the top.

Congratulations! You have just experienced a production-ready setup that can
reload itself automatically after every training! Simply add the training or
evaluation command to your *crontab*, and your setup will be able to re-deploy
itself automatically in a regular interval.