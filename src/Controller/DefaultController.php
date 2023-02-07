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
