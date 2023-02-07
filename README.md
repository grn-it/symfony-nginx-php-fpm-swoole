# Symfony Web Application run via nginx+php-fpm or nginx+swoole 

The purpose of the application is to demonstrate asynchronous requests and set up a web server through nginx+php-fpm or nginx+swoole.

Usually, when processing an HTTP request, all operations are performed synchronously,  
that is, in order to proceed to the next operation, you must wait for the current one to finish.  
This may be the reason for the long processing of the HTTP request.  

In some cases, you can separate fragments from business logic into separate API endpoints,  
which can be called microservices and call them asynchronously from the main request.  
That is, when a single HTTP request is made, many HTTP subrequests will be executed in parallel.  
This will reduce the HTTP request processing time and the web server will be able to process more HTTP requests.

This controller sends 16 asynchronous HTTP requests, parallelizing the execution of useful work.  
Symfony HTTP Client executes requests asynchronously by default.  

Methods that do not use the functions of the Symfony framework, Doctrine and other components  
can be moved to separate microservices on the Swoole web server using coroutines to perform operations asynchronously.

In this case, the microservice is designed as a regular API endpoint.

```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Contracts\HttpClient\HttpClientInterface;

class DefaultController extends AbstractController
{
    #[Route('/', name: 'app_default')]
    public function index(HttpClientInterface $httpClient): Response
    {
        /**
         * HTTP Client make 16 async requests
         * 
         * http_client.max_host_connections = 16 (default 6)
         * @see /config/packages/framework.yaml
         */
        $responses = [];
        foreach (range(1, 16) as $value) {
            $responses[] = $httpClient->request('GET', 'http://nginx/api/rand');
        }

        $result = [];
        foreach ($responses as $response) {
            $result[] = $response->getContent();
        }

        return $this->render('default/index.html.twig', [
            'controller_name' => 'DefaultController',
            'result' => implode(',', $result)
        ]);
    }

    #[Route('/api/rand', name: 'app_api_rand')]
    public function rand(): Response
    {
        return new Response((string) rand());
    }
}
```
