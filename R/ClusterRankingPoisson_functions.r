#Cluster Ranking Poisson functions
 #note: replaced theta with theta

library(tidyverse)
library(reshape2)
library(clue)
library(Hmisc)
library(RColorBrewer)

npmle.pois <- function(y,ti=rep(1,length(y)),k=NULL,n.iter=1000,row_names=NULL) {
  #y, persontime ti
  if (is.null(k)) {
    theta<-sort(y/ti) #sorted probabilities.
    k<-length(theta) #number of groups to start
  } else {
    theta <- seq(min(y/ti),max(y/ti),length=k)
  }
  p_theta <- rep(1/k,k) #evenly spaced probabilities between 0 and 1 for groups?

  E_z <- matrix(NA,length(y),k)
  for (j in 1:n.iter) {
    for (i in 1:k) {
      E_z[,i] <- log(p_theta[i])+dpois(y, ti*theta[i],log=TRUE) #E-step
    }
    E_z <- t(apply(E_z,1,function(x) exp(x-max(x))/sum(exp(x-max(x))))) #E_z will be
    p_theta <- apply(E_z,2,mean) #M-step
    theta <- y%*%E_z/ti%*%E_z
  }

  ord<-order(theta)
  theta<-c(theta[ord])
  p_theta<-p_theta[ord]

  p_theta <- tapply(p_theta,cumsum(!duplicated(round(theta,8))),sum)
  theta <- theta[!duplicated(round(theta,8))]

  E_z <- matrix(NA,length(y),length(theta))
  for (i in 1:length(theta)) {
    E_z[,i] <- log(p_theta[i])+dpois(y,ti*theta[i],log=TRUE)
  }
  E_z <- t(apply(E_z,1,function(x) exp(x-max(x))/sum(exp(x-max(x)))))

  rownames(E_z)<-row_names
  colnames(E_z)<-signif(theta,3)

  return(list(theta=theta, p_theta=p_theta, post_theta=E_z))
}

# rank_cluster.pois <- function(y,n,k=NULL,scale=identity,weighted=TRUE,n.iter=1000,n.samp=10000,row_names=NULL) {
#   #if we always label parameters as theta, p_theta, posterior should be same. shouldnt depend on data type
#   N <- length(y)

#   npmle_res <- npmle.pois(y,n,k,n.iter,row_names)

#   smp <- apply(npmle_res$post_theta,1,
#                function(x,theta,n.samp)
#                  sample(theta,n.samp,replace=TRUE,prob=x),
#                theta=scale(npmle_res$theta),n.samp=n.samp)
#   smp <- t(smp)
#   smp.ord <- apply(smp,2,sort)

#   if (weighted) wgt <- 1/pmax(.Machine$double.eps,apply(smp,1,var)) else wgt <- rep(1,N)

#   loss <- matrix(NA,N,N)
#   for (i in 1:N) {
#     for (j in 1:N) {
#       loss[i,j] <- wgt[i] * mean((smp[i,]-smp.ord[j,])^2)
#     }
#   }

#   rnk <- as.numeric(solve_LSAP(loss))
#   grp <- match(apply(smp.ord,1,getmode),scale(npmle_res$theta))[rnk]
#   grp <- factor(grp)
#   p_grp <- npmle_res$post_theta[cbind(1:N,as.numeric(grp))]
#   levels(grp) <- signif(npmle_res$theta,3)

#   ord <- order(rnk)

#   #break this into a new function
#   CI <- poisconf(y,n) #this depends on data type. TODO find new for pois

#   ranked_table <- data_frame(name=row_names,rank=rnk,group=factor(grp),
#                              y=y,n=n,p=y/n,
#                              p_LCL=CI[,2],p_UCL=CI[,3],
#                              pm=c(npmle_res$post_theta%*%npmle_res$theta),
#                              p_grp=p_grp)
#   ranked_table <- ranked_table[ord,]
#   ranked_table$name <- factor(ranked_table$name,levels=ranked_table$name,ordered=TRUE)

#   posterior <- npmle_res$post_theta[ord,]

#   return(list(ranked_table=ranked_table,posterior=posterior,theta=npmle_res$theta,pr_theta=npmle_res$p_theta))
# }

#same for binomial. use universal binomial functions here
# getmode <- function(v) { #same
#   uniqv <- unique(v)
#   uniqv[which.max(tabulate(match(v, uniqv)))]
# }
#
# plot_rt <- function(rc,xlab="Proportion") { #same for each data type
#   post_df <- melt(rc$posterior)
#   post_df$group <- rc$ranked_table$group[match(post_df$Var1,rc$ranked_table$name)]
#   post_df$p_grp <- rc$ranked_table$p_grp[match(post_df$Var1,rc$ranked_table$name)]
#
#   return(ggplot(rc$ranked_table,aes(y=name,x=p,color=group,alpha=p_grp))+
#            geom_point(pch=3)+
#            geom_point(aes(x=pm),pch=4)+
#            geom_point(data=post_df,aes(y=Var1,x=as.numeric(Var2),color=group,size=value,alpha=value))+
#            geom_errorbarh(aes(xmin=p_LCL,xmax=p_UCL),height=0)+
#            scale_y_discrete("",limits=rev(levels(rc$ranked_table$name)))+
#            scale_x_continuous(xlab,breaks=rc$theta[!duplicated(round(rc$theta,2))],
#                               labels=round(rc$theta[!duplicated(round(rc$theta,2))],3),minor_breaks=rc$theta)+
#            scale_color_manual(values=rep(brewer.pal(8,"Dark2"),1+floor(length(levels(rc$ranked_table$group))/8)))+
#            scale_size_area(max_size=5)+
#            scale_alpha(limits=c(0,1),range=c(0,1))+
#            theme_bw()+
#            guides(color=FALSE,size=FALSE,alpha=FALSE))
# }

