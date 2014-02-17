The Common LaTeX Service Interface
==================================

The Common LaTeX Service Interface (CLSI) is an HTTP API for compiling LaTeX
documents. Requests can be sent in either XML or JSON.
The main access point to the service is via 

    http://clsi.scribtex.com/clsi/compile

An example JSON request looks like

    {
        "compile" : {
            "token" : "...",
            "options" : {
                "output_format" : "pdf",
                "compiler"      : "latex"
            },
            "resources" : [
                {
                    "path"    : "main.tex",
                    "content" : "\\documentclass{article} \\begin{document} Hello world! \\input{chapter1.tex} \\end{document}"
                },
                {
                    "path"     : "chapter1.tex",
                    "url"      : "http://scribtex.github.com/clsi/examples/chapter1.tex",
                    "modified" : "2012-02-14 12:36:54" 
                }
            ],
            "rootResourcePath" : "main.tex"
        }
    }

The corresponding request in XML would be

    < TODO doc type here >
    <compile>
        <token>...</token>
        <options>
            <output-format>pdf</output-format>
            <compiler>latex</compiler>
        </options>
        <resources root-resource-path="main.tex">
            <resource path="main.tex"><!CDATA[
                \documentclass{article}
                \begin{document}
                Hello world! 
                \input{chapter1.tex}
                \end{document}
            ]></resource>
            <resource
                path="chapter1.tex"
                url="http://scribtex.github.com/clsi/examples/chapter1.tex"
                modified="2012-02-14 12:36:54">
            </resource>
        </resources>
    </compile>

These requests should be sent as POST requests to /clsi/compile, e.g.

    curl --data-binary @request.json
    http://clsi.scribtex.com/clsi/compile?format=json

or

    curl --data-binary @request.xml http://clsi.scribtex.com/clsi/compile

Note that XML is assumed to be the default format unless otherwise specified.

Request Format
==============

Token
-----

Every request must include your API access token under the _token_ option. This
can currently only be obtained by an email request to team@scribtex.com.

Resources
---------

Every request must contain a list of _resources_ (files to included in the
compilation), containing at least one resource. Resources must have a _path_
attribute, and either a _content_ or an _url_ attribute. For XML requests, the
content should be provided as the contents of <resource> tag rather than as an
attribute. More information about each attribute is given below:

* _path_ - This specifies where the file should be written to on disk before
  performing the compile. Any directories are created automatically so only the
  full file path of each file needs to be supplied.
* _url_ - An URL where the contents of the file can be downloaded from. The
  response from the URL is written verbatim into the file before compilation.
  Content downloaded from URLs is cached for an arbitrary length of time so the
  URL may not be downloaded with every request to the CLSI. The cache can be
  invalidated using the _modified_ property which is explained in more detail
  below.
* _content_ - Alternatively, the file contents may be specified directly. For
  speed, it is generally quicker to provide the file contents from URLs where
  possible as these can be cached on disk for quicker access.
* _modified_ - If providing the file via an URL this specifies when the file was
  last modified. This should be a string formatted like "YYYY-MM-DD hh:mm:ss"
  (TODO: Check if there is an official way to write this). Note that times
  should be provided in UTC as the server records when the data was last fetched
  in UTC (this is currently regarded as a slight bug. Instead the URL should be
  redownloaded if the modified date is ahead of the previously supplied modified
  date). If no modified date is provided, a cached version of the URL will
  always be used where available.

Root Resource Path
------------------

This specifies the main file which LaTeX should be run on. LaTeX will
be called with something like

    latex <root-resource-path>

The root resource path defaults to "main.tex".

Options
-------

The CLSI provides multiple compilers and output formats which can be specified
in the options section.

TODO: Copy paste from wiki

Response Format
===============

The response follows a similar schema to the request, and is returned in the
same format as the request. An example JSON response is:

    {
        "compile" : {
            "status"     : "success",
            "compile_id" : "...",
            "output_files" : [
                {
                    "url"      : "http://clsi.scribtex.com/output/.../output.pdf",
                    "mimetype" : "application/pdf",
                    "type"     : "pdf"
                }
            ],
            "logs" : [
                {
                    "url"      : "http://clsi.scribtex.com/output/.../output.log",
                    "mimetype" : "text/plain",
                    "type"     : "log"
                }
            ]
        }
    }

The corresponding XML would be:

    ...

Status
------

The status can be either:

* _success_ - The compile ran successfully and an output document was produced.
* _failure_ - For some reason the compile was unable to run or produce any
  output. More information is given in the _error_ attribute explained below.
* _compiling_ - The compile has not yet finished. See _Asynchronous Compiling_
  below.

Errors
------

If there was a problem with the request, or the compile was unable to run for
some reason, the response will contain an error section:

    {
        "compile" : {
            "error" { 
                "type"    : "NoOutputProduced",
                "message" : "No output files were produced" 
            },
            ...
        }
    }

or the corresponding XML:

    ...

Possible errors are:

TODO: Copy from Wiki.

Compile ID
----------

Each request is given a unique ID which is returned as the _compile_id_
attribute. This can be used to later refer to the same compile. This is mainly
useful when compiling asynchronously (see below).

Output Files and Logs
---------------------

Any output files and logs which are produced are returned in the _output_files_
and _logs_ attributes respectively. These are collections of items with the
following properites:

TODO: Copy paste from Wiki

Asynchronous Compiling
======================

By default the HTTP connection is left open until the compile is
finished and then the response is returned. While the CLSI is comparatively fast,
compiling a LaTeX document can still take a long time and this can leave you
with a connection sitting open for a while. 

The asynchronous options tells the CLSI to return immediately, before the
compilation is finished. A unique ID is provided which allows you to
poll the server to find out of the compile is complete.

Asynchronous compiling is enabled by passing the _asynchronous_ option in the
request:

    {
        "compile" : {
            "options" : {
                "asynchronous" : true,
                ...
            },
            ...
        }
    }

or 

    <compile>
        <options>
            <asynchronous>true</asynchronous>
            ...
        </options>
        ...
    </compile>

The CLSI will return a response immediately, except there will be no files
listed yet, and the status will be _compiling_. E.g.

    {
        "compile" : {
            "status"      : "compiling",
            "compile_id" : "..."
        }
    }

To check on the progress of a compile you can perform a GET request to 

    http://clsi.scribtex.com/output/<compile-id>/response.json

or 

    http://clsi.scribtex.com/output/<compile-id>/response.xml

depending on the format you would like.

The response will contain a status as above, which will either be _compiling_ if
the compile is still going on, or _success_ or _failure_ if it has finished. Any
output files will be listed when they are available.

We recommend polling at progressively longer intervals, e.g. 0.2s, 0.5s, 0.8s,
1s, 2s.
