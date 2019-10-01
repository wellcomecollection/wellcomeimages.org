"use-strict";
const https = require("https");
const querystring = require("querystring");

function createRedirect(location, excludeDomain) {
  return {
    status: "301",
    statusDescription: "Found",
    headers: {
      location: [
        {
          key: "Location",
          value: excludeDomain
            ? location
            : `https://wellcomecollection.org${location}`
        }
      ],
      "x-powered-by": [
        {
          key: "x-powered-by",
          value: "@weco/wiRedirector"
        }
      ]
    }
  };
}

async function apiFetch(path) {
  const options = {
    path: `/catalogue/v2${path}`,
    host: "api.wellcomecollection.org",
    method: "GET"
  };
  let body = "";
  return new Promise((resolve, reject) => {
    https
      .request(options, res => {
        res
          .on("data", chunk => {
            body += chunk;
          })
          .on("end", () => {
            try {
              resolve(JSON.parse(body));
            } catch (e) {
              reject("API JSON parsing error");
            }
          });
      })
      .on("error", e => {
        reject(e);
      })
      .end();
  });
}

exports.handler = async event => {
  const cf = event.Records[0].cf;
  const request = cf.request;

  // This is for images that we're serving from wellcomelibrary.org
  if (request.querystring && request.uri.match("/ixbin/imageserv")) {
    // e.g. http://wellcomeimages.org/ixbin/imageserv?MIRO=L0054052
    const params = querystring.parse(request.querystring);
    if (params.MIRO) {
      const redirect = createRedirect(
        `https://iiif.wellcomecollection.org/image/${params.MIRO}.jpg/full/125,/0/default.jpg`,
        true
      );
      return redirect;
    }
  }

  if (request.querystring && request.uri.match("/ixbin/hixclient")) {
    // e.g. http://wellcomeimages.org/ixbin/hixclient.exe?MIROPAC=V0042017
    const params = querystring.parse(request.querystring);
    if (params.MIROPAC) {
      const apiResponse = await apiFetch(`/works?query=${params.MIROPAC}`);
      const onlyOne =
        apiResponse.results.length === 1 ? apiResponse.results[0] : null;
      const redirect = onlyOne
        ? createRedirect(
            `/works/${onlyOne.id}?wellcomeImagesUrl=${request.uri}`
          )
        : createRedirect(
            `/works?query=${params.MIROPAC}&wellcomeImagesUrl=${request.uri}`
          );
      return redirect;
    }
  }

  // e.g. http://wellcomeimages.org/indexplus/image/hats.html
  // or:  http://wellcomeimages.org/indexplus/image/L0035269.html
  const searchTermMatch = request.uri.match(/\/indexplus\/image\/(.*)\.html/i);
  if (searchTermMatch) {
    const apiResponse = await apiFetch(`/works?query=${searchTermMatch[1]}`);
    const onlyOne =
      apiResponse.results.length === 1 ? apiResponse.results[0] : null;
    const redirect = onlyOne
      ? createRedirect(`/works/${onlyOne.id}?wellcomeImagesUrl=${request.uri}`)
      : createRedirect(
          `/works?query=${searchTermMatch[1]}&wellcomeImagesUrl=${request.uri}`
        );
    return redirect;
  }

  // e.g. http://wellcomeimages.org/indexplus/gallery/AIDS posters.html
  const galleryMatch = request.uri.match(/\/indexplus\/gallery\/(.*)\.html/i);
  if (galleryMatch) {
    const redirect = createRedirect(
      `/works?query=${galleryMatch[1]}&wellcomeImagesUrl=${request.uri}`
    );
    return redirect;
  }

  // e.g. http://wellcomeimages.org/redirect?query={query}
  if (request.querystring && request.uri.match("/redirect")) {
    const params = querystring.parse(request.querystring);
    const apiResponse = await apiFetch(`/works?query=${params.query}`);
    const onlyOne =
      apiResponse.results.length === 1 ? apiResponse.results[0] : null;
    const redirect = onlyOne
      ? createRedirect(`/works/${onlyOne.id}`)
      : createRedirect(`/works?query=${params.query}`);
    return redirect;
  }

  const redirect = createRedirect(`/works?wellcomeImagesUrl=${request.uri}`);
  return redirect;
};
