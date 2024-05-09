# Static Web Application Delivery Recommendations

This document outlines efficient DevOps strategies for deploying client-side rendered applications, such as those built with React JS, across various environments on Azure. The focus is on a straightforward method for managing environment-specific configurations at release time, aiming to minimize complexity and impact on existing codebases.
<br/>

## Deployment Strategies for Single Page Applications

For static web applications, configurations are typically set during the build process, requiring separate builds for different environments like dev, test, uat, and live. This can be time-consuming if the build process is lengthy.

In ReactJS applications, environment configurations are managed using “REACT_APP” .env properties set at compile time. The standard practice is to rebuild the app for each environment, which contradicts the “Build once, deploy everywhere” principle. To adhere to this principle, the configuration must be separated from the build process, allowing the same build to be deployed across various environments with distinct configurations.

Several strategies exist to achieve this, each with its own level of effort, advantages, and drawbacks. Some of these have been outlined below, but first is a recommendation for a pragmatic approach that requires minimal changes to existing codebases.
<br/>
## Recommendation

The numerous strategies listed below each have their own benefits and drawbacks, however I feel ["8. Injecting Global Variables"](#8-injecting-global-variables) is the most intuitive and is straightforward to apply to an existing codebase. Simply add some global variables in Javascript to either in a separate .js file or directly into your index.html. The index.html file is the entrypoint to your application and because it is located in the public folder, it will not be minified or bundled when the application is built for production. As a result, the variables contained within are much more accessible and the file can be updated easily, without rebuilding the application.

This first [example](public/env.js) shows how to define the environment variables in a separate file that will not be processed by Webpack.

![Separate File](images/separate-file-env.png)

This file is then included in the public folder of the React application and is loaded in the [index.html](public/index.html) file:

![Separate File Include](images/separate-file-include.png)

This particular strategy has been implemented in the [deploy.sh](deploy.sh) script in this repository. The script is used to deploy the application to an Azure App Service using zip deploy. The example includes a step to update the env.js file containing the environment variables directly in the deployment zip before publishing it to the Azure App Service. In this way, the environment variables can be updated without rebuilding the application.

If you have very few global variables, it is also possible to define them in a script block, directly in the index.html. With the use of placeholders in the file, it is trivial to find and replace these with relevant values at the time of deployment:

![How to define environment variables](./images/inline-env.png)
</br>
As discussed above, traditional apps such as React, embed the environment variables in the build and in that case, they are accessed using **process.env**. As we are loading a small script block containing the variables when the user first accesses the sit, they will instead become available using the **window**, like so:

![alt text](images/using-env.png)

Note the uppercase "ENV" which has been named intentionally to differentiate it from the standard **process.env** and ensure it is visible to devs consuming the codebase. Also shown above, is the use of the Nullish coalescing operator (??) to provide a default value in case the environment variable is not defined.

With these changes in place, you can now deploy the production build of your React application, but all the environment variables will be defined in the unbundled/non-minified public folder. Use any search and replace tool to find the placeholders or substitute an entire .js file, depending on your chosen approach. After the page is refreshed, the new values will be in effect.

<br/>

## A Working Example

The [deploy.sh](deploy.sh) shell script in this repository is a working example of how to deploy a React application to an Azure App Service using zip deploy. The script includes a step to update an env.js file containing the environment variables prior to the release. In this example, it is then patched directly into the single deployment package when publishing it to an Azure App Service. In this way, the environment variables are updated without rebuilding the application.

To execute the script, you will need to update the following variables at the top of the script:

- **UNIQUE_BASE_NAME**: A unique base name for the Azure resources (e.g., my-test-app).
- **SUBSCRIPTION**: The Azure subscription ID.
- **REGION**: Optionally you can specify the region to deploy into, however this will default to Australia East if not set.

Executing the script will build and package the application once, and then update the environment variables in the React application without rebuilding it. The script will pause to indicate the initial state before updating it again to display its final state:

![alt text](images/deploy-script.png)

*Note: The script was developed to be executed under a bash shell on the Windows Subsystem for Linux (WSL) or a Linux environment. The first step installs an extra dependency to ensure it hast the ability to load a window from the Windows default browser. It may require modifications to run on other platforms.*
<br/><br/>

## Additional Strategies

Also, I favour the approach detailed above, I recognise there are a significant number of strategies for managing environment-specific configurations in client-side applications. Each approach has its own set of benefits and trade-offs, so it's essential to choose the one that best fits your project's requirements and constraints.

<br/>

### 1. Dynamic Configuration via Public Folder:
- **Approach**: Store environment-specific configuration files like `config.js` in the public folder of the React application, which is not processed by Webpack.
- **Effort**: Moderate setup effort to organize configuration files and modify the build pipeline.
- **Pros**: Simplifies the CI/CD pipeline by using the same build for all environments.
- **Cons**: Configuration files are publicly accessible, which might be a security concern.
- **Source**: Discussed in the [Cevo blog](https://cevo.com.au/post/how-to-build-once-and-deploy-many-for-react-app-in-ci-cd/).

### 2. Environment Variable Injection at Runtime:
- **Approach**: Use tools like React-Inject-Env to inject environment variables into the application at runtime rather than during the build process.
- **Effort**: Requires initial setup in the CI/CD pipeline to ensure correct variable injection.
- **Pros**: Highly flexible and allows for last-minute configuration changes.
- **Cons**: May require additional tooling or setup in the deployment environment.
- **Source**: [A Build Once, Deploy Many Implementation Guide for React Apps with GitHub Actions and React-Inject-Env](https://medium.com/@liamhp/build-once-deploy-many-for-react-apps-with-github-actions-and-react-inject-env-f56aa78ffa44)

### 3. External Configuration File:
- **Approach**: Use an external `config.json` that is fetched at application startup to load configuration dynamically.
- **Effort**: Low to moderate effort, involving creating and managing the config file outside the build process.
- **Pros**: Easy to update without needing to rebuild or redeploy the application.
- **Cons**: Potential delay in application startup due to the fetch operation.
- **Source**: Explained in detail on [mikesir87's blog](https://blog.mikesir87.io/2021/07/build-once-deploy-everywhere-for-spas/).

### 4. Using CI/CD Pipeline for Environment Switching:
- **Approach**: Automate the switching of environment configurations during the deployment phase without rebuilding.
- **Effort**: High setup effort to script and test the CI/CD pipeline steps.
- **Pros**: Builds are consistent across all environments; reduces build time.
- **Cons**: Complexity in pipeline setup and maintenance.
- **Source**: Commonly referenced in discussions about DevOps practices for SPAs.

### 5. Server-Side Rendering for Dynamic Injects:
- **Approach**: Use server-side rendering to dynamically inject environment variables into the application at runtime.
- **Effort**: High due to the need for server-side capabilities and additional coding.
- **Pros**: Offers greater control over environment-specific configurations.
- **Cons**: Increases complexity and resource usage of the application.
- **Source**: Discussed in the context of React and [Redux documentation](https://redux.js.org/usage/server-rendering#inject-initial-component-html-and-state).

### 6. Webpack Environment Plugin:
- **Approach**: Utilize Webpack's EnvironmentPlugin to manage environment variables during the build process.
- **Effort**: Moderate effort to configure Webpack appropriately.
- **Pros**: Integrates smoothly into existing Webpack builds, easy to use once set up.
- **Cons**: Still requires a build per environment if variables are used in the code directly.
- **Source**: Detailed in [Webpack's official documentation](https://webpack.js.org/plugins/environment-plugin/).

### 7. Containerization:
- **Approach**: Package the application in a container that can be deployed across any environment.
- **Effort**: High initial effort to set up Docker or other container technologies.
- **Pros**: Highly portable and consistent across all deployment environments.
- **Cons**: Requires container management and orchestration knowledge.
- **Source**: General knowledge and best practices in cloud-native development.

### 8. Injecting Global Variables:
- **Approach**: Consider all static assets as immutable and utilise the public scope to host an index.html that is unique to each environment. By including versioned references to the web application static assets and setting the environment variables in the index.html, it effectively becomes a deployment manifest.
- **Effort**: Low to medium effort to update index.html in your deployment process for each environment and update code to use window.env rather than process.env.
- **Pros**: Highly portable and consistent across all deployment environments.
- **Cons**: Configuration files are publicly accessible, which might be a security concern.
- **Source**: [Injecting Data from the Server into the Page](https://create-react-app.dev/docs/title-and-meta-tags/#injecting-data-from-the-server-into-the-page)

### 9. Global Variables + Pre-rendering:
- **Approach**: As an extension of the previous approach, you can use a pre-rendering service to inject the environment variables into the index.html file before serving it to the client. This can be achieved in a number of ways such as [Server-side Rendering (SSR) with ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/client-side/spa/react?view=aspnetcore-8.0&tabs=visual-studio), [Azure Static Web Apps Snippets](https://learn.microsoft.com/en-us/azure/static-web-apps/snippets) or [Server-side Includes (SSI)](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/serversideinclude) in Azure App Service.
- **Effort**: Medium effort and impact depending on the pre-rendering technique chosen but has the same requirement update code to use window.env rather than process.env.
- **Pros**: Highly portable and consistent across all deployment environments and environment variables are incorporated by the server rather than requiring major changes to the client-side code.
- **Cons**: Depending on the method chosen, there may be additional complexity involved in moving to a new platform such as Azure Static Web Apps.
- **Sources**:
    - [Server-side Rendering (SSR) with ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/client-side/spa/react?view=aspnetcore-8.0&tabs=visual-studio)
    - [Azure Static Web Apps Snippets](https://learn.microsoft.com/en-us/azure/static-web-apps/snippets)
    - [Server-side Includes (SSI)](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/serversideinclude)
      <br/>

## References

How to "Build Once and Deploy Many" for React App in CI/CD - Cevo
https://cevo.com.au/post/how-to-build-once-and-deploy-many-for-react-app-in-ci-cd/

A Build Once, Deploy Many Implementation Guide for React Apps with GitHub Actions and React-Inject-Env | by Liam Patty | Medium
https://medium.com/@liamhp/build-once-deploy-many-for-react-apps-with-github-actions-and-react-inject-env-f56aa78ffa44

Build Once and Deploy Everywhere for SPAs – mikesir87's blog
https://blog.mikesir87.io/2021/07/build-once-deploy-everywhere-for-spas/

Build once, deploy many in React | Profinit blog
https://profinit.eu/en/blog/build-once-deploy-many-in-react-dynamic-configuration-properties/

React Application: Build Once, Deploy Anywhere Solution - DEV Community
https://dev.to/eamonnprwalsh/react-application-build-once-deploy-anywhere-solution-507m

Environment Variables in JavaScript: process.env
https://dmitripavlutin.com/environment-variables-javascript/

Managing Front-end JavaScript Environment Variables
https://robertcooper.me/post/front-end-javascript-environment-variables

Title and Meta Tags | Create React App
https://create-react-app.dev/docs/title-and-meta-tags/#generating-dynamic-meta-tags-on-the-server

reactjs - How to inject pod environment variables values into React app on runtime? - Stack Overflow
https://stackoverflow.com/questions/70085518/how-to-inject-pod-environment-variables-values-into-react-app-on-runtime

EnvironmentPlugin | webpack
https://webpack.js.org/plugins/environment-plugin/

Server Rendering | Redux
https://redux.js.org/usage/server-rendering#inject-initial-component-html-and-state

The Most Common XSS Vulnerability in React.js Applications | by Emelia Smith | Node Security | Medium
https://medium.com/node-security/the-most-common-xss-vulnerability-in-react-js-applications-2bdffbcc1fa0

Injecting Data from the Server into the Page | Create React App
https://create-react-app.dev/docs/title-and-meta-tags/#injecting-data-from-the-server-into-the-page
